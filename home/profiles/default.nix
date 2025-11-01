let
  mkProfile = hostname: {...}: {
    imports = [
      ../features/global.nix

      (./. + "/${hostname}.nix")
    ];
  };
in {
  sunflower = mkProfile "sunflower";
}
