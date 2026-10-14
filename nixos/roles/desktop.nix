{ pkgs, ... }:

{
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

      nerd-fonts.comic-shanns-mono
    ];

    fontconfig = {
      hinting.autohint = true;

      defaultFonts = {
        serif = [ "Noto Serif" "Noto Color Emoji" ];
        sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
        monospace = [ "ComicShannsMono Nerd Font" "Noto Color Emoji" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  services = {
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
