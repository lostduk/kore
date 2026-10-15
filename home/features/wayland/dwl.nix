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
in {
  home.packages = with pkgs; [ wmenu wl-clipboard xdg-utils screenshot ];
}
