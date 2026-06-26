{ config, ... }:

{
  programs.git = {
    enable = true;

    ignores = [
      "CLAUDE.md"
      ".claude/"
      "**/.claude/settings.local.json"
    ];

    settings = {
      user = {
        name = "lostduk";
        email = "hi@lostduk.com";

        signing.key = "0x024E39A2037D1BBC";
      };

      alias = {
        l = "log --oneline";
        lg = "log --oneline --decorate --graph";

        s = "status";

        fuck = "reset --hard";
        shit = "reset --soft";
      };

      init.defaultBranch = "main";

      gpg.program = "${config.programs.gpg.package}/bin/gpg2";

      commit = {
        verbose = true;
        gpgSign = true;
      };
    };
  };
}
