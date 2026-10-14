{ inputs, outputs, config, lib, pkgs, utils, modulesPath, ... }:

# Policy for every host. Values under mkForce are invariants: roles and
# hosts must not weaken them.
let
  impermanence = config.kore.impermanence.enable;
  rollback = impermanence && config ? disko && config.disko.devices.disk ? main;

  rootDevice = config.fileSystems."/".device;
  rootUnit = "${utils.escapeSystemdPath rootDevice}.device";
in {
  imports = [
    inputs.impermanence.nixosModules.impermanence

    ( modulesPath + "/profiles/minimal.nix" )
  ];

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };
  time.timeZone = "UTC";

  nix = {
    package = pkgs.nixVersions.latest;

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    settings = {
      keep-outputs = false;
      keep-derivations = false;
      auto-optimise-store = true;

      trusted-users = [ "root" "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;

    flake = {
      setFlakeRegistry = false;
      setNixPath = false;
    };

    config = {
      allowUnfree = lib.mkForce false;
      allowBroken = lib.mkForce false;
    };
  };

  system.tools = {
    nixos-build-vms.enable = false;
    nixos-enter.enable = false;
    nixos-generate-config.enable = false;
    nixos-install.enable = false;
    nixos-option.enable = false;
  };

  networking = {
    domain = "lostduk.com";

    useDHCP = true;
    enableIPv6 = lib.mkForce false;

    firewall = {
      enable = lib.mkForce true;
      allowPing = lib.mkForce false;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  services = {
    pcscd.enable = true;

    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [{
        path = "${lib.optionalString impermanence "/persist"}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
    };
  };

  security = {
    protectKernelImage = true;

    audit = {
      enable = true;
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };

    sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = lib.mkForce true;
    };

    auditd.enable = true;
    pam.sshAgentAuth.enable = true;
  };

  users = {
    mutableUsers = lib.mkForce false;

    users.root.hashedPassword = lib.mkForce "!";
  };

  environment = {
    defaultPackages = lib.mkForce [];

    persistence."/persist" = {
      enable = impermanence;
      hideMounts = false;

      directories = [
        "/srv"
        "/var/lib/nixos"
        "/var/lib/systemd"
      ];
    };
  };

  programs.nano.enable = false;

  fileSystems = lib.mkIf impermanence {
    "/persist".neededForBoot = true;
  };

  system.activationScripts.persistent-dirs = lib.mkIf impermanence {
    deps = [ "users" ];
    text =
      let
        mkHomePersist = user: lib.optionalString user.createHome ''
          mkdir -p /persist${user.home}
          chown ${user.name}:${user.group} /persist${user.home}
          chmod ${user.homeMode} /persist${user.home}
        '';
      in
        lib.concatLines (map mkHomePersist (lib.attrValues config.users.users));
  };

  assertions = [{
    assertion = rollback -> config.boot.initrd.systemd.enable;
    message = "kore: root rollback needs boot.initrd.systemd.enable";
  }];

  boot.initrd = lib.mkIf rollback {
    supportedFilesystems = [ "btrfs" ];

    systemd.services.wipe-root = {
      wantedBy = [ "initrd.target" ];
      requires = [ rootUnit ];
      after = [ rootUnit ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /tmp
        MNTPOINT=$(mktemp -d)
        (
          mount ${rootDevice} "$MNTPOINT"
          trap 'umount "$MNTPOINT"' EXIT

          if [[ -e $MNTPOINT/@ ]]; then
            echo "Backing up root..."
            mkdir -p $MNTPOINT/old_roots
            mv "$MNTPOINT/@" "$MNTPOINT/old_roots/@_$(date "+%Y-%m-%-d_%H:%M:%S")"
          fi

          echo "Deleting 7+ days old roots..."
          find "$MNTPOINT/old_roots" -mindepth 1 -maxdepth 1 \
            -mtime +7 \
            -exec btrfs sub del -R {} +

          echo "Creating new root..."
          btrfs sub cre "$MNTPOINT/@"
        )
      '';
    };
  };
}
