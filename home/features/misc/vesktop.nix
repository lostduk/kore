{
  programs.vesktop = {
    enable = true;
    settings = {
      tray = false;
      minimizeToTray = false;
      hardwareAcceleration = false; # enable this makee vesktop crash
      discordBranch = "stable";
    };
  };

  home.persistence."/persist".directories = [ ".config/vesktop" ];
}
