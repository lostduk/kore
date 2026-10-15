{ inputs, modulesPath, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko

    ( modulesPath + "/installer/scan/not-detected.nix" )
  ];

  boot = {
    kernelModules = [ "kvm-intel" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    };
  };

  hardware = {
    graphics.enable = true;
    cpu.intel.updateMicrocode = true;
  };

  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
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
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "crypted";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = let
                options = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
              in {
                "/@" = {
                  mountpoint = "/";
                  mountOptions = options;
                };
                "/@nix" = {
                  mountpoint = "/nix";
                  mountOptions = options;
                };
                "/@persist" = {
                  mountpoint = "/persist";
                  mountOptions = options;
                };
              };
            };
          };
        };
      };
    };
  };
}
