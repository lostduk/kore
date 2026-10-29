{ inputs, config, lib, modulesPath, ... }:

let
  gateway = "100.213.253.237";
in {
  imports = [
    inputs.disko.nixosModules.disko

    ( modulesPath + "/profiles/qemu-guest.nix" )
  ];

  networking = {
    useDHCP = false;

    interfaces.enp0s4.ipv4.addresses = [{ address = config.kore.currentHost.ipv4; prefixLength = 32; }];

    defaultGateway = {
      address = gateway;
      interface = "enp0s4";
    };
  };

  zramSwap.enable = true;
  services.journald.settings.Journal.SystemMaxUse = "500M";

  boot = {
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };

    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
    };
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        boot = {
          size = "1M";
          type = "EF02";
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = lib.mapAttrs (_: mountpoint: {
              inherit mountpoint;
              mountOptions = [ "compress=zstd" "noatime" ];
            }) { "/@" = "/"; "/@nix" = "/nix"; "/@persist" = "/persist"; };
          };
        };
      };
    };
  };
}
