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
          set -e

          TARGET="/home/lostduk"

          find "$TARGET" -mindepth 1 -maxdepth 1 \
            ! -name 'documents' \
            ! -name '.gnupg' \
            ! -name '.password-store' \
            ! -name '.local' \
            -exec rm -r {} +

          if [ -d "$TARGET/.local" ]; then
            find "$TARGET/.local" -mindepth 1 -maxdepth 1 \
              ! -name 'share' \
              -exec rm -r {} +
          fi

          if [ -d "$TARGET/.local/share" ]; then
            find "$TARGET/.local/share" -mindepth 1 -maxdepth 1 \
              ! -name 'opencode' \
              -exec rm -r {} +
          fi

          if [ -d "$TARGET/.local/share/opencode" ]; then
            find "$TARGET/.local/share/opencode" -mindepth 1 -maxdepth 1 \
              ! -name 'auth.json' \
              -exec rm -r {} +
          fi
        '';
      };
    };
  })];
}

