{ inputs, outputs, config, lib, ... }:

let
  inherit (config.kore.currentHost) users;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "claude-code"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };

    users = lib.genAttrs users
      (_: { imports = [ ../home/base.nix ] ++ map (feat: ../home/${feat}.nix) config.kore.currentHost.feats.home; });
  };

  sops.secrets = lib.mkMerge (map (user:
    lib.genAttrs config.home-manager.users.${user}.kore.secrets (_: { owner = user; })
  ) users);
}
