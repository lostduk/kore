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

    packages = with pkgs; [ pass vesktop ];

    persistence."/persist/home/lostduk" = {
      directories = [ "documents" ".config/vesktop" ".mozilla" ".gnupg" ];
      allowOther = true;
    };
  };
}
