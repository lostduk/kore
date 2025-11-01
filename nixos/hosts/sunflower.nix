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
    };
  };

  users.users.lostduk = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "tmp";
  };

  hardware = {
    graphics.enable = true;
    cpu.intel.updateMicrocode = true;
  };
}
