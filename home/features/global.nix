{ inputs, config, pkgs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.home-manager.impermanence ];

  home = {
    username = "lostduk";
    homeDirectory = "/home/lostduk";
    stateVersion = "25.11";

    sessionVariables = {
      # Fuck Google
      GOSUMDB = "off";
      GOPROXY = "direct";
      GOTELEMETRY = "off";
      GOTOOLCHAIN = "local";
    };

    packages = with pkgs; [ firefox pass goofcord ];

    persistence."/persist/home/lostduk" = {
      allowOther = true;
      directories = [
        "documents"
        ".mozilla" 
        ".config/goofcord" 
        ".password-store"
      ];
    };
  };
}
