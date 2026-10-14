{ pkgs, ... }:

{
  home.packages = with pkgs; [ wmenu wl-clipboard xdg-utils ];

  programs.bash.profileExtra = ''
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
      exec /etc/xdg/dwl-session
    fi
  '';
}
