{ pkgs, config, osConfig, lib, ... }:

let
  identity = osConfig.kore.identities.${config.home.username};
in {
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    pinentry.package = pkgs.pinentry-curses;
  };

  programs = {
    gpg =  {
      enable = true;
      settings.trust-model = "tofu+pgp";
      scdaemonSettings.disable-ccid = true;

      publicKeys = lib.optional (identity.gpgKey != null) {
        source = identity.gpgKey;
        trust = "ultimate";
      };
    };

    bash.initExtra = ''
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
      gpg-connect-agent UPDATESTARTUPTTY /bye > /dev/null
    '';
  };
}
