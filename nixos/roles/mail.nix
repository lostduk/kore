{ config, lib, pkgs, ... }:

let
  inherit (config.networking) domain;
  inherit (config.sops) placeholder;
  fqdn = config.kore.domains.mail;
  root = "/srv/mail";
  cert = config.security.acme.certs.${fqdn}.directory;
  admin = builtins.head config.kore.currentHost.users;
  adminEmail = config.kore.identities.${admin}.email;

  mailboxes = lib.filterAttrs (_: identity:
    identity.email != null && lib.hasSuffix "@${domain}" identity.email
  ) config.kore.identities;

  mailboxMap = pkgs.writeText "kore-mail-mailboxes" (lib.concatLines (lib.mapAttrsToList (_: identity:
    "${identity.email} ${identity.email}"
  ) mailboxes));

  roleMap = pkgs.writeText "kore-mail-roles" (lib.concatMapStrings (name:
    "${name}@${domain} ${adminEmail}\n"
  ) [ "postmaster" "abuse" "dmarc" ]);

  devicesFile = "/run/kore-mail/devices";

  aliasMap = "/var/lib/postfix/conf/kore-aliases";
  aliasMaps = [ "texthash:${roleMap}" "texthash:${aliasMap}" ];

  spamSieve = pkgs.writeText "spam.sieve" ''
    require ["fileinto", "mailbox"];
    if header :is "X-Spam" "Yes" {
      fileinto :create "Junk";
      stop;
    }
  '';

  learnSpam = pkgs.writeText "learn-spam.sieve" ''
    require ["vnd.dovecot.pipe", "copy", "imapsieve"];
    pipe :copy "learn-spam";
  '';

  learnHam = pkgs.writeText "learn-ham.sieve" ''
    require ["vnd.dovecot.pipe", "copy", "imapsieve", "environment", "variables"];
    if environment :matches "imap.mailbox" "*" {
      set "mailbox" "''${1}";
    }
    if string "''${mailbox}" "Trash" {
      stop;
    }
    pipe :copy "learn-ham";
  '';

  learn = kind: lib.getExe (pkgs.writeShellScriptBin "learn-${kind}" ''
    exec ${config.services.rspamd.package}/bin/rspamc learn_${kind}
  '');
in {
  assertions = [{
    assertion = lib.elem "web" config.kore.currentHost.roles;
    message = "kore: the mail role needs the web role for ACME";
  } {
    assertion = mailboxes ? ${admin};
    message = "kore: mail admin ${admin} needs an email @${domain}";
  }];

  sops.secrets = lib.concatMapAttrs (name: _: {
    "mail/${name}/password" = {};
    "mail/${name}/aliases".restartUnits = [ "postfix-setup.service" "postfix.service" ];
    "mail/${name}/devices".restartUnits = [ "dovecot.service" ];
  }) mailboxes;

  sops.templates.kore-mail-passwd = {
    group = config.services.dovecot2.settings.default_internal_group;
    mode = "0440";
    content = lib.concatLines (lib.mapAttrsToList (name: identity:
      "${identity.email}:{CRYPT}${placeholder."mail/${name}/password"}::::${root}/${name}::"
    ) mailboxes);
  };

  services.nginx.virtualHosts.${fqdn} = {
    enableACME = true;
    forceSSL = true;
    globalRedirect = domain;
  };

  security.acme.certs.${fqdn}.reloadServices = [ "postfix.service" "dovecot.service" ];

  services.postfix = {
    enable = true;
    enableSubmissions = true;
    rootAlias = adminEmail;
    postmasterAlias = adminEmail;

    submissionsOptions = {
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      smtpd_sender_restrictions = "reject_sender_login_mismatch";
      milter_macro_daemon_name = "ORIGINATING";
    };

    settings.main = {
      myhostname = fqdn;
      mydomain = domain;
      myorigin = domain;
      mydestination = [ "localhost" ];
      recipient_delimiter = "+";

      virtual_mailbox_domains = [ domain ];
      virtual_mailbox_maps = [ "texthash:${mailboxMap}" ];
      virtual_alias_maps = aliasMaps;
      virtual_transport = "lmtp:unix:private/dovecot-lmtp";
      smtpd_sender_login_maps = [ "texthash:${mailboxMap}" ] ++ aliasMaps;

      smtpd_tls_chain_files = [ "${cert}/key.pem" "${cert}/fullchain.pem" ];
      smtpd_tls_security_level = "may";
      smtp_tls_security_level = "may";
      smtpd_helo_required = true;
      disable_vrfy_command = true;
    };
  };

  systemd.services.postfix-setup.script = lib.mkAfter ''
    : > ${aliasMap}
    ${lib.concatStrings (lib.mapAttrsToList (name: identity: ''
      sed 's/#.*//' ${config.sops.secrets."mail/${name}/aliases".path} | tr -s '[:space:]' '\n' | while read -r alias; do
        [ -n "$alias" ] || continue
        if [[ ! "$alias" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
          echo "kore-mail: invalid alias '$alias' for ${name}" >&2
          exit 1
        fi
        echo "$alias@${domain} ${identity.email}" >> ${aliasMap}
      done
    '') mailboxes)}
  '';

  services.rspamd = {
    enable = true;
    postfix.enable = true;
    locals = {
      "redis.conf".text = ''
        servers = "${config.services.redis.servers.rspamd.unixSocket}";
      '';
      "classifier-bayes.conf".text = ''
        autolearn = true;
      '';
      "dkim_signing.conf".text = ''
        try_fallback = false;
        allow_username_mismatch = true;
        domain {
          ${domain} {
            selector = "kore";
            path = "/var/lib/rspamd/dkim/${domain}.kore.key";
          }
        }
      '';
    };
  };

  users.users.${config.services.rspamd.user}.extraGroups = [ config.services.redis.servers.rspamd.group ];

  services.redis.servers.rspamd = {
    enable = true;
    port = 0;
  };

  systemd.services.kore-mail-dkim = {
    wantedBy = [ "rspamd.service" ];
    before = [ "rspamd.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = config.services.rspamd.user;
      Group = config.services.rspamd.group;
      StateDirectory = "rspamd";
      StateDirectoryMode = "0700";
    };
    script = ''
      dir=/var/lib/rspamd/dkim
      if [ ! -f "$dir/${domain}.kore.key" ]; then
        mkdir -p "$dir"
        ${config.services.rspamd.package}/bin/rspamadm dkim_keygen -b 2048 -s kore -d ${domain} \
          -k "$dir/${domain}.kore.key" > "$dir/${domain}.kore.txt"
      fi
    '';
  };

  environment.systemPackages = [ pkgs.dovecot_pigeonhole ];

  services.dovecot2 = {
    enable = true;
    sieve.pipeBins = [ (learn "spam") (learn "ham") ];
    settings = {
      dovecot_config_version = "2.4.0";
      dovecot_storage_version = "2.4.0";

      protocols = {
        imap = true;
        lmtp = true;
      };

      mail_uid = "vmail";
      mail_gid = "vmail";
      mail_driver = "maildir";
      mail_path = "~/Maildir";
      recipient_delimiter = "+";

      ssl = "required";
      ssl_server_cert_file = "${cert}/fullchain.pem";
      ssl_server_key_file = "${cert}/key.pem";

      auth_mechanisms = [ "plain" "login" ];
      auth_username_format = "%{user | lower}";
      auth_username_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890.-_@+";

      "passdb passwd-file".passwd_file_path = config.sops.templates.kore-mail-passwd.path;
      "userdb passwd-file".passwd_file_path = config.sops.templates.kore-mail-passwd.path;
      "passdb devices" = {
        driver = "passwd-file";
        passwd_file_path = devicesFile;
      };

      "namespace inbox" = {
        inbox = true;
        separator = "/";
        mailbox = [
          { _section.name = "Drafts"; special_use = "\\Drafts"; auto = "subscribe"; }
          { _section.name = "Sent"; special_use = "\\Sent"; auto = "subscribe"; }
          {
            _section.name = "Junk";
            special_use = "\\Junk";
            auto = "subscribe";
            "sieve_script learn-spam" = {
              type = "before";
              cause = "copy";
              path = learnSpam;
            };
          }
          { _section.name = "Trash"; special_use = "\\Trash"; auto = "subscribe"; }
          { _section.name = "Archive"; special_use = "\\Archive"; auto = "subscribe"; }
        ];
      };

      "protocol lmtp" = {
        mail_plugins.sieve = true;
        "sieve_script spam" = {
          type = "before";
          path = spamSieve;
        };
      };

      "protocol imap".mail_plugins.imap_sieve = true;
      sieve_plugins.sieve_imapsieve = true;
      "imapsieve_from Junk"."sieve_script learn-ham" = {
        type = "before";
        cause = "copy";
        path = learnHam;
      };

      service = [
        {
          _section.name = "imap-login";
          "inet_listener imap".port = 0;
        }
        {
          _section.name = "lmtp";
          "unix_listener /var/lib/postfix/queue/private/dovecot-lmtp" = {
            mode = "0600";
            user = config.services.postfix.user;
            group = config.services.postfix.group;
          };
        }
        {
          _section.name = "auth";
          "unix_listener /var/lib/postfix/queue/private/auth" = {
            mode = "0660";
            user = config.services.postfix.user;
            group = config.services.postfix.group;
          };
        }
      ];
    };
  };

  systemd.services.dovecot = {
    after = [ "postfix-setup.service" ];
    wants = [ "postfix-setup.service" ];
    serviceConfig.RuntimeDirectory = [ "kore-mail" ];
    preStart = lib.mkAfter (''
      install -m 0440 -g ${config.services.dovecot2.settings.default_internal_group} /dev/null ${devicesFile}
    '' + lib.concatStrings (lib.mapAttrsToList (name: identity: let
      local = builtins.head (lib.splitString "@" identity.email);
    in ''
      sed 's/#.*//' ${config.sops.secrets."mail/${name}/devices".path} | while read -r device hash rest; do
        [ -n "$device" ] || continue
        if [[ ! "$device" =~ ^[a-z0-9][a-z0-9-]*$ || "$hash" != '$'* || -n "$rest" ]]; then
          echo "kore-mail: invalid device line for ${name}" >&2
          exit 1
        fi
        echo "${local}+$device@${domain}:{CRYPT}$hash::::${root}/${name}::user=${identity.email}" >> ${devicesFile}
      done
    '') mailboxes));
  };

  systemd.tmpfiles.rules = [ "d ${root} 0700 vmail vmail -" ];

  networking.firewall.allowedTCPPorts = [ 25 465 993 ];

  environment.persistence."/persist".directories = [
    "/var/lib/postfix"
    "/var/lib/dovecot"
    "/var/lib/rspamd"
    "/var/lib/redis-rspamd"
  ];
}
