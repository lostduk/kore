{ config, pkgs, ... }:

{
  home = {
    username = "lostduk";
    homeDirectory = "/home/lostduk";
    stateVersion = "26.11";

    sessionVariables = {
      # Fuck Google
      GOSUMDB = "off";
      GOPROXY = "direct";
      GOTELEMETRY = "off";
      GOTOOLCHAIN = "local";
    };

    packages = with pkgs; [ pass ];

    persistence."/persist".directories = [
      "documents"
      ".mozilla"
      ".password-store"
    ];
  };
}
