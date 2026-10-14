{ config, osConfig, ... }:

let
  identity = osConfig.kore.identities.${config.home.username};
in {
  programs.git = {
    enable = true;

    ignores = [
      "CLAUDE.md"
      ".claude/"
      "**/.claude/settings.local.json"
    ];

    settings = {
      user = {
        name = config.home.username;
        email = identity.email;

        signing.key = identity.gpg;
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
