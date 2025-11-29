{ config, ... }:

{
  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.local/cache";
    
    userDirs = {
      enable = true;
      documents = "${config.home.homeDirectory}/documents";
      videos = "${config.home.homeDirectory}/media";
      music = "${config.home.homeDirectory}/media";
      pictures = "${config.home.homeDirectory}/media";
      download = "${config.home.homeDirectory}";
      desktop = "${config.home.homeDirectory}";
      publicShare = "${config.home.homeDirectory}";
      templates = "${config.home.homeDirectory}";
    };
  };
}
