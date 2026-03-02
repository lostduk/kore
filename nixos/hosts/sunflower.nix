{ inputs, modulesPath, pkgs, ... }:

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

  users.users.lostduk = {
    password = "tmp";
    isNormalUser = true;

    extraGroups = [ "wheel" ];
    subUidRanges = [{ startUid = 100000; count = 65536; }];
    subGidRanges = [{ startGid = 100000; count = 65536; }];
  };

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ libGL ];
    };
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
            mountOptions = [ "defaults" "uid=0" "gid=0" "fmask=0077" "dmask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            name = "crypted";
            type = "luks";
            extraFormatArgs = [ "--type luks2" ];
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = let
                options = [ "compress=zstd" "noatime" "space_cache=v2" "discard=async" "ssd" ];
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
