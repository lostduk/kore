{ inputs, outputs, config, lib, pkgs, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "UTC";

  nix = {
    package = pkgs.nixVersions.latest;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      keep-outputs = false;
      keep-derivations = false;
      auto-optimise-store = true;

      trusted-users = [ "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;

    config = {
      allowUnfree = lib.mkForce false;
      allowBroken = lib.mkForce false;
    };
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
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
    };
  };

  security = {
    protectKernelImage = true;

    audit = {
      enable = true;
      rules = [ "-a exit,always, -F arch=b64 -S execve" ];
    };

    sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = lib.mkForce true;
    };

    auditd.enable = true;
    pam.enableSSHAgentAuth = true;
  };

  users = {
    mutableUsers = lib.mkForce false;

    users.root.hashedPassword = lib.mkForce "!";
  };

  environment = {
    defaultPackages = lib.mkForce [];

    persistence."/persist" = {
      hideMounts = false;

      directories = [
        "/srv"
        "/var/lib/nixos"
        "/var/lib/systemd"
      ];
    };
  };

  boot.initrd = let
    rootDevice = config.fileSystems."/".device;
    systemdStage1 = config.boot.initrd.systemd.enable;
    # TODO: Delete old root, but I can't get this to work since something
    # is wrong. In the "Creating a new root" part, our root is not /@, but it's
    # /@_(date) I'm not sure why. Maybe it works as intended since i wrote this
    # a long, long time ago.
    script = ''
      echo "Mounting..."
      mkdir -p /tmp
      MNTPOINT=$(mktemp -d)
      (
        mount ${rootDevice} "$MNTPOINT"
        trap 'umount "$MNTPOINT"' EXIT

        echo "Creating a new root..."
        mv "$MNTPOINT/@" "$MNTPOINT/@_$(date "+%Y-%m-%-d_%H:%M:%S")"

        echo "Creating a blank subvolume..."
        btrfs sub cre "$MNTPOINT/@"
      )
    '';
  in {
    supportedFilesystems = [ "btrfs" ];
    postDeviceCommands = lib.mkIf (!systemdStage1) (lib.mkBefore script);

    systemd.services.wipe-root = lib.mkIf (systemdStage1) {
      description = "Wipe root";
      wantedBy = [ "initrd.target" ];
      requires = [ "dev-mapper-crypted.device" ];
      before = [ "sysroot.mount" ];
      after = [
        "dev-mapper-crypted.device"
        "systemd-cryptsetup@crypted.service"
      ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.type = "oneshot";
      script = script;
    };
  };

  fileSystems."/persist".neededForBoot = true;
}
