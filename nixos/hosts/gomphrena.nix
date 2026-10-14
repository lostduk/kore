{ inputs, lib, ... }:

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  kore.impermanence.enable = false;

  security = {
    audit.enable = lib.mkForce false;
    auditd.enable = lib.mkForce false;
  };

  hardware.graphics.enable = lib.mkForce false;

  wsl = {
    enable = true;
    defaultUser = "lostduk";

    usbip = {
      enable = true;
      autoAttach = [ "1-14" ];
    };
  };
}
