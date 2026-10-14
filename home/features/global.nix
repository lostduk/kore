{ osConfig, pkgs, ... }:

{
  programs.man.enable = false;
  manual.manpages.enable = false;

  home = {
    stateVersion = osConfig.system.stateVersion;

    sessionVariables = {
      # Fuck Google
      GOSUMDB = "off";
      GOPROXY = "direct";
      GOTELEMETRY = "off";
      GOTOOLCHAIN = "local";
    };

    packages = with pkgs; [ pass ];

    persistence."/persist" = {
      enable = osConfig.kore.impermanence.enable;

      directories = [
        "documents"
        ".mozilla"
        ".password-store"
      ];
    };
  };
}
