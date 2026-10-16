{ inputs, outputs, config, lib, ... }:

let
  inherit (config.networking) domain;
  mailHost = lib.any (host: lib.elem "mail" host.roles) (lib.attrValues config.kore.hosts);
  mailUsers = lib.filter (user:
    let email = config.kore.identities.${user}.email;
    in email != null && lib.hasSuffix "@${domain}" email
  ) config.kore.currentHost.users;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };

    users = lib.genAttrs config.kore.currentHost.users
      (_: outputs.homeModules.${config.networking.hostName});
  };

  sops.secrets = lib.mkIf (config.kore.secrets.enable && mailHost) (lib.listToAttrs (map (user:
    lib.nameValuePair "mail/${user}" { owner = user; }
  ) mailUsers));

  programs.fuse.userAllowOther = true;
}
