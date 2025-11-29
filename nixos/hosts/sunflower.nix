{ pkgs, inputs, modulesPath, ... }:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default

    ( modulesPath + "/installer/scan/not-detected.nix" )
  ];

  wsl = {
    enable = true;
    defaultUser = "lostduk";
    useWindowsDriver = true;

    usbip = {
      enable = true;
      autoAttach = [ "1-14" ];
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
    graphics.enable = true;
    cpu.intel.updateMicrocode = true;
  };
}
