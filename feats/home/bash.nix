{ osConfig, config, pkgs, ... }:

let
  fetch = pkgs.writeShellApplication {
    name = "fetch";
    runtimeInputs = [ pkgs.coreutils pkgs.gnused pkgs.gnugrep osConfig.nix.package ];
    text = ''
      os="$(sed -n 's/^ID=//p' /etc/os-release) $(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"')"

      vendor="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || true)"
      model="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
      case "$model" in ""|*"Default string"*|*"To be filled"*|*"System Product Name"*)
        model="$(cat /sys/class/dmi/id/board_name 2>/dev/null || true)" ;;
      esac
      host="''${vendor%% *} $model"

      read -r up _ < /proc/uptime
      up=''${up%.*}
      days=$((up / 86400)) hours=$((up % 86400 / 3600)) mins=$((up % 3600 / 60))
      uptime="''${mins}m"
      [ "$hours" -gt 0 ] && uptime="''${hours}h $uptime"
      [ "$days" -gt 0 ] && uptime="''${days}d $uptime"

      while read -r key value _; do
        case "$key" in
          MemTotal:) total=$value ;;
          MemAvailable:) avail=$value ;;
        esac
      done < /proc/meminfo
      memory="$(((total - avail) / 1024))M / $((total / 1024))M"

      user="''${USER:-$(id -un)}"
      pkgs=0
      for profile in /run/current-system "/etc/profiles/per-user/$user"; do
        [ -e "$profile" ] || continue
        root="$(readlink -f "$profile")"
        count="$(nix-store -qR "$profile" \
          | while read -r path; do [ "$path" != "$root" ] && [ -d "$path" ] && printf '%s\n' "''${path##*/}"; done \
          | grep -vE -- '-(doc|man|info|dev|bin)$' | grep -cE '[0-9]+\.[0-9]' || true)"
        pkgs=$((pkgs + count))
      done

      r=$'\e[31m' g=$'\e[32m' y=$'\e[33m' d=$'\e[37m' f=$'\e[97m' z=$'\e[0m'

      art=(
        "$r    .-.-.    "
        "$r  .( $y@@@$r ).  "
        "$r (  $y@@@@@$r  ) "
        "$r  '.($y@@@$r).'  "
        "$g  \\_  |  _/  "
        "$g    '-|-'    "
        "$g      |      "
      )
      info=(
        "$f$user$d@$f$HOSTNAME"
        "''${g}os$z      $os"
        "''${g}host$z    $host"
        "''${g}kernel$z  $(uname -r)"
        "''${g}uptime$z  $uptime"
        "''${g}pkgs$z    $pkgs"
        "''${g}memory$z  $memory"
      )

      printf '\n'
      for i in "''${!art[@]}"; do
        printf '  %s%s  %s%s\n' "''${art[$i]}" "$z" "''${info[$i]}" "$z"
      done
      printf '\n'
    '';
  };
in {
  home.packages = [ fetch ];

  kore.greeting = "fetch";

  programs = {
    eza.enable = true;

    bash = {
      enable = true;
      shellAliases = {
        l = "eza --git -s type";
        ls = "l -l";
        la = "l -la";
        tree = "l --tree";
        grep = "grep --color";

        dev = "cd $HOME/documents/dev";
      };

      initExtra = ''
        if [[ -z "''${TMUX:-}" && -z "''${SSH_CONNECTION:-}" && "$TERM" == foot* ]]; then
          ${config.kore.greeting}
        fi
      '';
    };
  };
}
