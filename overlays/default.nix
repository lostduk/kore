{ inputs, outputs, ... }:

{
  # https://m7.rs/git/nix-config/tree/overlays/default.nix#line-13
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (_: flake:
        let
          inherit (final.stdenv.hostPlatform) system;
          legacyPackages = (flake.legacyPackages or {}).${system} or {};
          packages = (flake.packages or {}).${system} or {};
        in
          if legacyPackages != {} then legacyPackages else packages
      )
      inputs;
  };

  modifications = final: prev: {
    dwl =
      let
        inherit (final) lib;
        hex = c: lib.removePrefix "#" c;
        colors = lib.getAttrs [ "bg" "fg" "surface" "green" "red" "teal" ] outputs.palette.colors;
      in
        (prev.dwl.override {
          configH = final.replaceVars ./dwl/config.h (
            lib.mapAttrs (_: c: "0x${hex c}ff") colors
            // lib.mapAttrs' (n: c: lib.nameValuePair "${n}Rgb" (hex c))
              (lib.getAttrs [ "bg" "fg" "surface" "green" ] colors)
          );
        }).overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./dwl/bar.patch
            ./dwl/gaps.patch
            ./dwl/garden.patch
          ];
          buildInputs = old.buildInputs ++ [ final.fcft final.pixman final.libdrm ];
        });
  };
}
