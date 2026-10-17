{ inputs, config, lib, pkgs, ... }:

let
  inherit (config.kore) admin identities lists;
  fqdn = config.kore.domains.lists;
  root = "/srv/lists";

  pollen = pkgs.stdenv.mkDerivation {
    pname = "pollen";
    version = "0-${inputs.greenhouse.shortRev or "dirty"}";

    src = "${inputs.greenhouse}/pollen";

    postPatch = ''
      cp config.def.h config.h
      substituteInPlace config.h \
        --replace-fail '"/srv/lists"' '"${root}"' \
        --replace-fail '"lists.lostduk.com"' '"${fqdn}"' \
        --replace-fail '"https://lists.lostduk.com/"' '""' \
        --replace-fail '"/usr/sbin/sendmail"' '"/run/wrappers/bin/sendmail"'
    '';

    makeFlags = [
      "PREFIX=$(out)"
      "CC=${pkgs.stdenv.cc.targetPrefix}cc"
    ];
  };

  owner = opts: identities.${if opts.owner != null then opts.owner else admin}.email;

  recipientMap = pkgs.writeText "kore-lists" (lib.concatMapStrings (list:
    "${list}@${fqdn} OK\n"
  ) (lib.attrNames lists));

  transportMap = pkgs.writeText "kore-lists-transport" "${fqdn} pollen:\n";
in {
  assertions = [{
    assertion = lib.elem "mail" config.kore.currentHost.feats.nixos;
    message = "kore: the lists feat needs the mail feat";
  }];

  users.groups.pollen = {};
  users.users.pollen = {
    isSystemUser = true;
    group = "pollen";
    home = root;
  };

  systemd.tmpfiles.rules = [ "d ${root} 0750 pollen pollen -" ];

  systemd.services.kore-lists = {
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" "systemd-tmpfiles-setup.service" ];
    before = [ "postfix.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "pollen";
      Group = "pollen";
      UMask = "0027";
    };
    script = lib.concatStrings (lib.mapAttrsToList (list: opts: ''
      mkdir -p '${root}/${list}'
      printf '%s\n' ${lib.escapeShellArg opts.description} > '${root}/${list}/description'
      printf '%s\n' ${lib.escapeShellArg (owner opts)} > '${root}/${list}/owner'
      printf '%s\n' ${opts.post} > '${root}/${list}/post'
      printf '%s\n' ${opts.subscribe} > '${root}/${list}/subscribe'
      ${if opts.private
        then "rm -f '${root}/${list}/public'"
        else "touch '${root}/${list}/public'"}
    '') lists);
  };

  services.postfix = {
    settings.main = {
      relay_domains = [ fqdn ];
      relay_recipient_maps = [ "texthash:${recipientMap}" ];
      transport_maps = [ "texthash:${transportMap}" ];
      pollen_destination_recipient_limit = 1;
    };

    settings.master.pollen = {
      type = "unix";
      privileged = true;
      chroot = false;
      command = "pipe";
      args = [ "flags=Rq" "user=pollen" "argv=${pollen}/bin/pollen \${user} \${extension}" ];
    };
  };

  services.rspamd.locals."settings.conf".text = ''
    lists {
      priority = high;
      rcpt = '/@${lib.escapeRegex fqdn}$/i';
      apply {
        actions {
          reject = 6;
        }
      }
    }
  '';
}
