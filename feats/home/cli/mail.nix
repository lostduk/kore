{ pkgs, config, osConfig, outputs, lib, ... }:

let
  user = config.home.username;
  identity = osConfig.kore.identities.${user};
  inherit (osConfig.networking) domain hostName;
  host = osConfig.kore.domains.mail;
  local = builtins.head (lib.splitString "@" identity.email);
  userName = "${local}+${hostName}@${domain}";
  secretName = "mail/${user}/devices/${hostName}";
  secret = osConfig.sops.secrets.${secretName}.path;
  outbox = "${config.xdg.stateHome}/mail/outbox";

  rgb = c: lib.concatMapStringsSep ";" (i: toString (lib.fromHexString (builtins.substring i 2 c))) [ 0 2 4 ];
  inherit (outputs.palette) hex;

  lmc = pkgs.lmc {
    from = "${user} <${identity.email}>";
    downloads = config.xdg.userDirs.download;
    ColSel = "48;2;${rgb hex.surface}";
    ColUnread = "1;38;2;${rgb hex.fg}";
    ColFlag = "38;2;${rgb hex.yellow}";
    ColStatus = "38;2;${rgb hex.dim};48;2;${rgb hex.bgAlt}";
  };

  notify = "${pkgs.libnotify}/bin/notify-send";

  hook = pkgs.writeShellScript "mii-hook" ''
    case $1 in
    new)
      ${lmc}/bin/lmc -p "$2" | {
        from= subject=
        while IFS= read -r line && [ -n "$line" ]; do
          case $line in
          'From: '*) from=''${line#From: } ;;
          'Subject: '*) subject=''${line#Subject: } ;;
          esac
        done
        name=''${from% <*}
        name=''${name#\"}
        name=''${name%\"}
        if [ -z "$name" ]; then
          name=''${from#<}
          name=''${name%>}
        fi
        exec ${notify} -a mail -c email.arrived "✉ ''${name:0:40} · ''${subject:0:80}"
      }
      ;;
    fail)
      exec ${notify} -a mail -u critical "✉ not sent: ''${3:0:120}"
      ;;
    esac
  '';
in {
  kore.secrets = [ secretName ];

  home.packages = [ lmc pkgs.mii ];

  systemd.user.tmpfiles.rules = map (dir: "d ${outbox}${dir} 0700 - - -") [ "" "/tmp" "/new" "/failed" ];

  home.persistence."/persist".directories = [ ".local/state/mail" ];

  systemd.user.services.mii = {
    Unit.Description = "mii IMAP mailbox mirror";

    Service = {
      ExecStart = "${pkgs.mii}/bin/mii -s ${host} -u ${userName} -p ${secret} -x ${hook}";
      Restart = "on-failure";
      RestartSec = 30;
    };

    Install.WantedBy = [ "default.target" ];
  };

  kore.greeting = lib.mkAfter ''
    unread=0
    for f in "''${XDG_CACHE_HOME:-$HOME/.cache}"/mail/INBOX/{new,cur}/*; do
      [[ -e $f && $f != *:2,*S* ]] && unread=$((unread + 1))
    done
    if (( unread > 0 )); then
      printf '  \e[32m✉\e[0m  %s unread mail\n\n' "$unread"
    fi
    unset f unread
  '';
}
