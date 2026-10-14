{
  programs.ssh = {
    enable = true;

    # Replaces the soon-to-be-removed legacy defaults; values mirror the
    # old programs.ssh.settings."*" block.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 30;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      gh = {
        HostName = "github.com";
        User = "git";
      };
    };
  };
}
