{ osConfig, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*".ServerAliveInterval = 30;

      gh = {
        HostName = "github.com";
        User = "git";
      };

      ld = {
        HostName = osConfig.kore.domains.git;
        User = "git";
      };
    };
  };
}
