{ config, lib, pkgs, ... }:

let
  inherit (config.networking) domain;
  inherit (config.sops) placeholder;
  inherit (config.kore) admin mailboxes identities;
  fqdn = config.kore.domains.mail;
  root = "/srv/mail";
  cert = config.security.acme.certs.${fqdn}.directory;
  adminEmail = mailboxes.${admin};

  localPart = email: builtins.head (lib.splitString "@" email);
  deviceSecret = name: device: "mail/${name}/devices/${device}";

  mailboxMap = pkgs.writeText "kore-mail-mailboxes" (lib.concatLines (lib.mapAttrsToList (_: email:
    "${email} ${email}"
  ) mailboxes));

  userdb = pkgs.writeText "kore-mail-users" (lib.concatLines (lib.mapAttrsToList (name: email:
    "${email}:::::${root}/${name}::"
  ) mailboxes));

  roleMap = pkgs.writeText "kore-mail-roles" (lib.concatMapStrings (name:
    "${name}@${domain} ${adminEmail}\n"
  ) [ "postmaster" "abuse" "dmarc" ]);

  aliasMap = "/var/lib/postfix/conf/kore-aliases";
  aliasMaps = [ "texthash:${roleMap}" "texthash:${aliasMap}" ];

  spamSieve = pkgs.writeText "spam.sieve" ''
    require ["fileinto", "mailbox"];
    if header :is "X-Spam" "Yes" {
      fileinto :create "Junk";
      stop;
    }
  '';
in {
  assertions = [{
    assertion = lib.elem "nginx" config.kore.currentHost.feats.nixos;
    message = "kore: the mail feat needs the nginx feat for ACME";
  } {
    assertion = mailboxes ? ${admin};
    message = "kore: mail admin ${admin} needs an email @${domain}";
  }] ++ lib.concatMap (name: map (device: {
    assertion = builtins.match "[a-z0-9][a-z0-9-]*" device != null;
    message = "kore: mail device name ${device} of ${name} is invalid";
  }) identities.${name}.devices) (lib.attrNames mailboxes);

  sops.secrets = lib.concatMapAttrs (name: _: {
    "mail/${name}/aliases".restartUnits = [ "postfix-setup.service" "postfix.service" ];
  } // lib.genAttrs (map (deviceSecret name) identities.${name}.devices) (_: {})) mailboxes;

  sops.templates.kore-mail-passwd = {
    group = config.services.dovecot2.settings.default_internal_group;
    mode = "0440";
    content = lib.concatLines (lib.concatLists (lib.mapAttrsToList (name: email: map (device:
      "${localPart email}+${device}@${domain}:{PLAIN}${placeholder.${deviceSecret name device}}::::::user=${email}"
    ) identities.${name}.devices) mailboxes));
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
      inet_protocols = "ipv4";
      internal_mail_filter_classes = [ "bounce" ];
    };
  };

  systemd.services.postfix-setup.script = lib.mkAfter ''
    : > ${aliasMap}
    ${lib.concatStrings (lib.mapAttrsToList (name: email: ''
      sed 's/#.*//' ${config.sops.secrets."mail/${name}/aliases".path} | tr -s '[:space:]' '\n' | while read -r alias; do
        [ -n "$alias" ] || continue
        if [[ ! "$alias" =~ ^[a-z0-9][a-z0-9._-]*$ ]]; then
          echo "kore-mail: invalid alias '$alias' for ${name}" >&2
          exit 1
        fi
        echo "$alias@${domain} ${email}" >> ${aliasMap}
      done
    '') mailboxes)}
  '';

  services.resolved.enable = false;

  services.unbound = {
    enable = true;
    settings.server = {
      interface = [ "127.0.0.1" ];
      access-control = [ "127.0.0.0/8 allow" ];
      do-ip6 = false;
      prefetch = true;
      hide-identity = true;
      hide-version = true;
    };
  };

  services.rspamd = {
    enable = true;
    postfix.enable = true;
    workers.controller.bindSockets = lib.mkForce [{
      socket = "/run/rspamd/controller.sock";
      mode = "0600";
    }];
    locals."fuzzy_check.conf".text = "enabled = false;";
    locals."dkim_signing.conf".text = ''
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
      "userdb passwd-file".passwd_file_path = userdb;

      "namespace inbox" = {
        inbox = true;
        separator = "/";
        mailbox = [
          { _section.name = "Sent"; special_use = "\\Sent"; auto = "subscribe"; }
          { _section.name = "Junk"; special_use = "\\Junk"; auto = "subscribe"; }
          { _section.name = "Archive"; special_use = "\\Archive"; auto = "subscribe"; }
          { _section.name = "Trash"; special_use = "\\Trash"; auto = "subscribe"; }
        ];
      };

      "protocol lmtp" = {
        mail_plugins.sieve = true;
        "sieve_script spam" = {
          type = "before";
          path = spamSieve;
        };
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
  };

  systemd.tmpfiles.rules = [ "d ${root} 0700 vmail vmail -" ];

  networking.firewall.allowedTCPPorts = [ 25 465 993 ];

  environment.persistence."/persist".directories = [
    "/var/lib/postfix"
    "/var/lib/dovecot"
    "/var/lib/rspamd"
  ];
}
