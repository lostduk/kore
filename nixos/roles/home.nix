{ inputs, outputs, config, lib, ... }:

{
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

  programs.fuse.userAllowOther = true;
}
