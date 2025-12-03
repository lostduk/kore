{
  programs.ssh = {
    enable = true;
    matchBlocks = {
      gh = {
        hostname = "github.com";
        user = "git";
      };
    }; 
  };
}
