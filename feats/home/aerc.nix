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
  c = outputs.palette.colors;

  mail-watch = pkgs.writers.writePython3Bin "mail-watch" { doCheck = false; } ''
    import email
    import email.policy
    import imaplib
    import os
    import subprocess
    import sys
    import time

    host, user, secret = sys.argv[1:]
    cache = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "mail")
    seen = None


    def write_unread(count):
        os.makedirs(cache, exist_ok=True)
        path = os.path.join(cache, "unread")
        with open(path + ".tmp", "w") as f:
            f.write(f"{count}\n")
        os.replace(path + ".tmp", path)


    def clean(text, limit):
        text = "".join(ch for ch in str(text) if ch.isprintable())
        return text[:limit]


    def notify(text):
        subprocess.run(["${pkgs.libnotify}/bin/notify-send", "-a", "mail", "-c", "email.arrived", text])


    def describe(msg):
        sender = "unknown"
        if msg["From"] is not None and msg["From"].addresses:
            address = msg["From"].addresses[0]
            sender = address.display_name or address.addr_spec
        subject = msg["Subject"] or "(no subject)"
        return f"✉ {clean(sender, 40)} · {clean(subject, 80)}"


    def check(imap):
        global seen
        _, data = imap.uid("SEARCH", None, "UNSEEN")
        unseen = set(data[0].split())
        write_unread(len(unseen))
        if seen is not None:
            new = sorted(unseen - seen, key=int)
            if len(new) > 3:
                notify(f"✉ {len(new)} new mail")
            else:
                for uid in new:
                    _, data = imap.uid("FETCH", uid, "(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT)])")
                    raw = next(part[1] for part in data if isinstance(part, tuple))
                    notify(describe(email.message_from_bytes(raw, policy=email.policy.default)))
        seen = unseen


    while True:
        try:
            with open(secret) as f:
                password = f.read().strip()
            imap = imaplib.IMAP4_SSL(host, timeout=60)
            imap.login(user, password)
            imap.select("INBOX", readonly=True)
            while True:
                check(imap)
                with imap.idle(duration=120) as idler:
                    for _ in idler:
                        break
        except (OSError, imaplib.IMAP4.error) as e:
            print(f"mail-watch: {e}", file=sys.stderr, flush=True)
            time.sleep(30)
  '';
in {
  kore.secrets = [ secretName ];

  accounts.email.accounts.${user} = {
    primary = true;
    address = identity.email;
    realName = user;
    inherit userName;
    passwordCommand = [ "cat" secret ];

    imap = {
      inherit host;
      port = 993;
      tls.enable = true;
    };
    smtp = {
      inherit host;
      port = 465;
      tls.enable = true;
    };

    folders = {
      inbox = "INBOX";
      sent = "Sent";
      drafts = "Drafts";
      trash = "Trash";
    };

    gpg = lib.mkIf (identity.gpg != null) {
      key = identity.gpg;
      signByDefault = false;
    };

    aerc = {
      enable = true;
      extraAccounts.cache-headers = true;
    };
  };

  programs.aerc = {
    enable = true;
    package = pkgs.aerc.override { withNotmuch = false; };

    extraConfig = {
      general.unsafe-accounts-conf = true;

      ui = {
        styleset-name = "garden";
        border-char-vertical = "│";
        border-char-horizontal = "─";
      };

      filters = {
        "text/plain" = "colorize";
        "text/html" = "html | colorize";
        "text/calendar" = "calendar";
        "message/delivery-status" = "colorize";
        "message/rfc822" = "colorize";
        ".headers" = "colorize";
      };
    };

    stylesets.garden = {
      global = {
        "*.default" = true;
        "*.normal" = true;

        "default.fg" = c.fg;
        "error.fg" = c.red;
        "warning.fg" = c.yellow;
        "success.fg" = c.green;

        "title.fg" = c.green;
        "title.bold" = true;
        "header.fg" = c.teal;
        "border.fg" = c.surface;

        "tab.fg" = c.dim;
        "tab.selected.fg" = c.fg;
        "tab.selected.bg" = c.surface;

        "statusline_default.fg" = c.dim;
        "statusline_default.bg" = c.bgAlt;
        "statusline_error.fg" = c.red;
        "statusline_success.fg" = c.green;

        "dirlist_default.fg" = c.dim;
        "dirlist_unread.fg" = c.fg;
        "dirlist_unread.bold" = true;

        "msglist_default.fg" = c.dim;
        "msglist_unread.fg" = c.fg;
        "msglist_unread.bold" = true;
        "msglist_flagged.fg" = c.yellow;
        "msglist_deleted.fg" = c.surface;
        "msglist_marked.fg" = c.magenta;
        "msglist_result.fg" = c.blue;

        "*.selected.bg" = c.surface;
        "*.selected.fg" = c.fg;

        "selector_focused.fg" = c.bg;
        "selector_focused.bg" = c.green;
        "completion_default.bg" = c.bgAlt;
        "completion_pill.bg" = c.surface;
        "spinner.fg" = c.green;
      };

      viewer = {
        "url.fg" = c.blue;
        "url.underline" = true;
        "header.bold" = true;
        "header.fg" = c.teal;
        "signature.fg" = c.dim;
        "diff_meta.bold" = true;
        "diff_chunk.fg" = c.teal;
        "diff_add.fg" = c.green;
        "diff_del.fg" = c.red;
        "quote_1.fg" = c.teal;
        "quote_2.fg" = c.blue;
        "quote_x.fg" = c.dim;
      };
    };
  };

  home.packages = [ mail-watch ];

  systemd.user.services.mail-watch = {
    Unit = {
      Description = "mail-watch unread mail notifier";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${mail-watch}/bin/mail-watch ${host} ${userName} ${secret}";
      Restart = "always";
      RestartSec = 30;
    };

    Install.WantedBy = [ "dwl-session.target" ];
  };

  programs.bash.initExtra = lib.mkAfter ''
    if [[ -z "''${TMUX:-}" && -z "''${SSH_CONNECTION:-}" && "$TERM" == foot* ]]; then
      read -r unread 2>/dev/null < "''${XDG_CACHE_HOME:-$HOME/.cache}/mail/unread"
      if [[ "''${unread:-0}" -gt 0 ]]; then
        printf '  \e[32m✉\e[0m  %s unread mail\n\n' "$unread"
      fi
      unset unread
    fi
  '';
}
