{ inputs, outputs, lib, ... }:

let
  mkSystem = system: hostname: lib.nixosSystem {
    system = system;
    specialArgs = { inherit inputs outputs; };
    modules = [
      ../features/global.nix
      ../features/kore.nix

      ../roles

      (./. + "/${hostname}.nix")

      { networking.hostName = "${hostname}"; }
      { system.stateVersion = "25.11"; }
    ];
  };
in {
  sunflower = mkSystem "x86_64-linux" "sunflower";
  gomphrena = mkSystem "x86_64-linux" "gomphrena";
}
