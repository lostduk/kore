{ inputs, outputs, lib, kore, ... }:

let
  mkSystem = hostname: host: lib.nixosSystem {
    specialArgs = { inherit inputs outputs kore; };
    modules = [
      ../features/global.nix
      ../features/kore.nix
      ../features/secrets.nix

      ./${hostname}.nix

      { networking.hostName = hostname; }
    ] ++ map (role: ../roles/${role}.nix) host.roles;
  };
in lib.mapAttrs mkSystem kore.hosts
