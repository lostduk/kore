{ inputs, outputs, config, pkgs, lib, ... }:

let
  roleName = "workstation";
  roleEnabled = lib.elem roleName config.kore.currentHost.roles;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager  ];

  config = lib.mkMerge [{} (lib.mkIf roleEnabled {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs outputs; };

      users.lostduk = outputs.homeConfigurations.${config.networking.hostName};
    };

    systemd.services.wipe-trash = {
      restartIfChanged = false;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "" ''
          find '/home/lostduk' -mindepth 1 -maxdepth 1 \
            ! -name 'documents' \
            ! -name '.gnupg' \
            ! -name '.password-store' \
            -exec rm -r {} +
        '';
      };
    };
  })];
}

