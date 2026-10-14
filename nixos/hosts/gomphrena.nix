{ inputs, lib, ... }:

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  # WSL can't mount /persist at boot.
  kore.impermanence.enable = false;

  # WSL can't register auditd ("Unable to set audit pid").
  security = {
    audit.enable = lib.mkForce false;
    auditd.enable = lib.mkForce false;
  };

  # CLI only here: no mesa/LLVM (~830 MiB).
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
