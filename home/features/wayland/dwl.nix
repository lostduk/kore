{ config, pkgs, ... }:

let
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [ grim slurp wl-clipboard coreutils ];
    text = ''
      case "''${1:-area}" in
        area) grim -g "$(slurp)" - | wl-copy -t image/png ;;
        output) grim -g "$(slurp -o)" - | wl-copy -t image/png ;;
        save)
          dir="${config.xdg.userDirs.pictures}/screenshots"
          mkdir -p "$dir"
          grim -g "$(slurp)" "$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
          ;;
        *) echo "usage: screenshot [area|output|save]" >&2; exit 1 ;;
      esac
    '';
  };

  volume = pkgs.writeShellApplication {
    name = "volume";
    runtimeInputs = with pkgs; [ wireplumber libnotify gawk coreutils ];
    text = ''
      sink=@DEFAULT_AUDIO_SINK@
      source=@DEFAULT_AUDIO_SOURCE@

      case "''${1:-}" in
        up) wpctl set-volume -l 1.0 "$sink" 5%+ ;;
        down) wpctl set-volume "$sink" 5%- ;;
        mute) wpctl set-mute "$sink" toggle ;;
        mic) wpctl set-mute "$source" toggle ;;
        *) echo "usage: volume [up|down|mute|mic]" >&2; exit 1 ;;
      esac

      if [ "$1" = mic ]; then
        target=$source
      else
        target=$sink
      fi
      state="$(wpctl get-volume "$target")"
      pct="$(awk '{ printf "%d", $2 * 100 + 0.5 }' <<< "$state")"

      if [ "$1" = mic ]; then
        case "$state" in *MUTED*) title="mic muted" ;; *) title="mic on" ;; esac
      else
        case "$state" in *MUTED*) title="muted" ;; *) title="volume $pct" ;; esac
      fi

      idfile="''${XDG_RUNTIME_DIR:-/tmp}/volume-notify-id"
      id="$(cat "$idfile" 2>/dev/null || echo 0)"
      notify-send -p -r "$id" -c volume -h "int:value:$pct" "$title" > "$idfile"
    '';
  };
in {
  home.packages = with pkgs; [ wmenu wl-clipboard xdg-utils playerctl screenshot volume ];
}
