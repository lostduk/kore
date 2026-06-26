{ inputs, outputs, lib, kore, ... }:

let
  mkSystem = hostname: host: lib.nixosSystem {
    system = host.system;
    specialArgs = { inherit inputs outputs kore; };
    modules = [
      ../features/global.nix
      ../features/kore.nix

      ../roles

      (./. + "/${hostname}.nix")

      { networking.hostName = "${hostname}"; }
      { system.stateVersion = "26.11"; }
    ];
  };
in lib.mapAttrs mkSystem kore.hosts
