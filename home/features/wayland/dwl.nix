{ pkgs, ... }:

{
  home.packages = with pkgs; [ dwl dmenu wl-clipboard xdg-utils ];
}
