{ inputs, ... }:

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  # WSL can't mount /persist at boot.
  kore.impermanence.enable = false;

  wsl = {
    enable = true;
    defaultUser = "lostduk";
    useWindowsDriver = true;

    usbip = {
      enable = true;
      autoAttach = [ "1-14" ];
    };
  };

  hardware = {
    graphics.enable = true;
    cpu.intel.updateMicrocode = true;
  };
}
