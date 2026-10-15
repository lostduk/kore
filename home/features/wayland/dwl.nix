{ pkgs, ... }:

{
  home.packages = with pkgs; [ wmenu wl-clipboard xdg-utils ];
}
