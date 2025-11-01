{ config, ... }:

{
  programs.git = {
    enable = true;

    userName = "lostduk";
    userEmail = "hi@lostduk.com";

    aliases = {
      l = "log --oneline";
      lg = "log --oneline --decorate --graph";

      s = "status";

      fuck = "reset --hard";
      shit = "reset --soft";
    };

    extraConfig = {
      init.defaultBranch = "main";

      user.signing.key = "0x024E39A2037D1BBC";

      gpg.program = "${config.programs.gpg.package}/bin/gpg2";

      commit = {
        verbose = true;
        gpgSign = true;
      };
    };
  };
}
