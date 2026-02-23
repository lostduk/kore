{
  programs.claude-code = {
    enable = true;
    settings = {
      theme = "dark";
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
        ask = [ "Edit" ];
        deny = [
          "WebFetch"
          "Bash(curl:*)"
          "Bash(git:*)"
          "Read(./.env)"
        ];
      };
      includeCoAuthoredBy = false;
    };
  };
}
