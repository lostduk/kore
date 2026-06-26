{ inputs, outputs, config, pkgs, lib, ... }:

let
  roleName = "home";
  roleEnabled = lib.elem roleName config.kore.currentHost.roles;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager  ];

  config = lib.mkMerge [{} (lib.mkIf roleEnabled {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "claude-code"
      ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs outputs; };

      users.lostduk = outputs.homeConfigurations.${config.networking.hostName};
    };

    programs.fuse.userAllowOther = true;
  })];
}

