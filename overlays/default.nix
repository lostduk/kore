{ outputs, ... }:

{
  modifications = final: prev: {
    dwl =
      let
        inherit (final) lib;
        hex = c: lib.removePrefix "#" c;
        colors = lib.getAttrs [ "bg" "fg" "surface" "green" "red" "teal" ] outputs.palette.colors;
      in
        (prev.dwl.override {
          wlroots_0_20 = prev.wlroots_0_20.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./dwl/wlroots-clipboard.patch ];
          });
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
