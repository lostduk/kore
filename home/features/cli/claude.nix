{ lib, config, pkgs, ... }:

let
  karpathySkills = pkgs.fetchFromGitHub {
    owner = "multica-ai";
    repo = "andrej-karpathy-skills";
    rev = "2c606141936f1eeef17fa3043a72095b4765b9c2";
    hash = "sha256-4z/wRdYH7UXRzF8RJU0sw8xbpx0BW/7CBv5sVEC2knY=";
  };
  nineArmSkills = pkgs.fetchFromGitHub {
    owner = "thananon";
    repo = "9arm-skills";
    rev = "167c83445c82a4e87161029fa70be400c659e849";
    hash = "sha256-sbPBkE/nqhMTqim7L1fu6q17i/j+fnjMlcv/JNyZZCg=";
  };
  mattPocockSkills = pkgs.fetchFromGitHub {
    owner = "mattpocock";
    repo = "skills";
    rev = "694fa30311e02c2639942308513555e61ee84a6f";
    hash = "sha256-NGRKdnHSBKoR48zGotmJ3zGXnQ58ogudv8T4Va/2DSY=";
  };
in {
  programs.claude-code = {
    enable = true;
    context = "${karpathySkills}/CLAUDE.md";
    settings = {
      theme = "dark";
      attribution = {
        commit = "";
        pr = "";
      };
      env = {
        # Fuck Anthorpic
        DISABLE_TELEMETRY = true;
        DISABLE_ERROR_REPORTING = true;
        DISABLE_BUG_COMMAND = true;
        CLAUDE_CODE_ENABLE_TELEMETRY = false;
        CLAUDE_CODE_DISABLE_FEEDBACK_SURVERY = true;
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = true;
      };
      permissions = {
        allow = [ "Edit" ];
        ask = [
          "WebFetch"
          "Bash(curl:*)"
          "Bash(git:*)"
        ];
        deny = [
          "Bash(git push *)"
          "Bash(git commit *)"
          "Read(./.env)"
        ];
      };
    };
    skills = {
      scrutinize = "${nineArmSkills}/skills/engineering/scrutinize";
      grill-with-docs = "${mattPocockSkills}/skills/engineering/grill-with-docs";
    };
  };
}

