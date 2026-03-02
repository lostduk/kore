{ config, pkgs, ... }:

{
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

    persistence."/persist" = {
      files = [
        ".local/share/opencode/auth.json"
      ];
      directories = [
        "documents"
        ".mozilla"
        ".gnupg"
        ".password-store"
        ".config/vesktop"
      ];
    };
  };
}
