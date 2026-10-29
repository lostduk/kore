{ inputs, lib, pkgs, modulesPath, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko

    ( modulesPath + "/installer/scan/not-detected.nix" )
  ];

  time.timeZone = "Asia/Bangkok";

  networking = {
    useNetworkd = true;
    useDHCP = false;
  };
  systemd.network.networks."10-ethernet" = {
    matchConfig.Type = "ether";
    networkConfig = {
      DHCP = "ipv4";
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
    };
    dhcpV4Config = {
      UseDNS = false;
      UseDomains = false;
    };
    linkConfig.RequiredForOnline = "routable";
  };

  boot = {
    kernelModules = [ "kvm-intel" ];

    loader = {
      systemd-boot = {
        enable = true;
        editor = false;
      };
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

    enableRedistributableFirmware = false;
    firmware = [
      (pkgs.runCommand "peony-firmware" { } ''
        cd ${pkgs.linux-firmware}/lib/firmware
        install -Dm444 -t $out/lib/firmware/amdgpu amdgpu/polaris12_*
        install -Dm444 -t $out/lib/firmware/rtl_nic rtl_nic/rtl8168h-2.fw
      '')
    ];
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
              subvolumes = lib.mapAttrs (_: mountpoint: {
                inherit mountpoint;
                mountOptions = [ "compress=zstd" "noatime" "ssd" "discard=async" ];
              }) { "/@" = "/"; "/@nix" = "/nix"; "/@persist" = "/persist"; };
            };
          };
        };
      };
    };
  };
}
