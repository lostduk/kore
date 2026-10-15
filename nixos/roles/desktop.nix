{ lib, pkgs, ... }:

let
  garden-status = pkgs.writeShellApplication {
    name = "garden-status";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      while :; do
        case "$(date +%-H)" in
          5|6) tod=dawn ;;
          7|8|9|10) tod=morning ;;
          11|12|13) tod=noon ;;
          14|15|16) tod=afternoon ;;
          17|18) tod=dusk ;;
          19|20|21) tod=eventide ;;
          *) tod=night ;;
        esac
        line="$(date "+%a %-d %b · $tod %H:%M")"
        printf '%s\n' "''${line,,}"
        sleep "$((60 - $(date +%-S)))"
      done
    '';
  };
in {
  programs.dwl = {
    enable = true;
    extraSessionCommands = "exec < <(${lib.getExe garden-status})";
  };

  environment.loginShellInit = ''
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
      /etc/xdg/dwl-session
      systemctl --user stop dwl-session.target
      exit
    fi
  '';

  xdg = {
    autostart.enable = true;
    icons.enable = true;
    mime.enable = true;
    sounds.enable = true;

    portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
      configPackages = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];

      wlr.enable = true;

      config.common = {
        default = [ "wlr" ];
      };
    };
  };

  fonts = {
    enableDefaultPackages = false;

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji

      fantasque-sans-mono
    ];

    fontconfig = {
      hinting.autohint = true;

      defaultFonts = {
        serif = [ "Noto Serif" "Noto Color Emoji" ];
        sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
        monospace = [ "Fantasque Sans Mono" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  services = {
    openssh.enable = false;

    udisks2.enable = true;

    pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;

      pulse.enable = true;
      jack.enable = true;

      wireplumber.enable = true;
    };
  };
}
