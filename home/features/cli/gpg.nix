{ pkgs, config, lib, ... }:

{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    pinentryPackage = pkgs.pinentry-curses;
  };

  programs = {
    gpg =  {
      enable = true;
      settings.trust-model = "tofu+pgp";
      scdaemonSettings.disable-ccid = true;
    };

    bash.initExtra = ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
      gpg-connect-agent UPDATESTARTUPTTY /bye > /dev/null
    '';
  };
}
