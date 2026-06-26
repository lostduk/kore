{ kore }:

let
  mkProfile = hostname: {...}: {
    imports = [
      ../features/global.nix

      (./. + "/${hostname}.nix")
    ];
  };
in builtins.mapAttrs (hostname: _: mkProfile hostname) kore.hosts
