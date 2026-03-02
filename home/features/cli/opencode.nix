{
  programs.opencode = {
    enable = true;
    web.enable = false;

    settings = {
      # go fuck ur self
      #formatter = "false";
      permission = {
        webfetch = "ask";
        read = {
          "*.env" = "deny";
          "*.env.*" = "deny";
          "*.env.example" = "allow";
        };
        bash = {
          "curl *" = "deny";
          "git *" = "deny";
        };
      };
    };
  };
}
