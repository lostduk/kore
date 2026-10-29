{ inputs, outputs, ... }:

{
  greenhouse = final: prev: {
    greenhouse = name: { replace ? {}, ... }@attrs: final.stdenv.mkDerivation (removeAttrs attrs [ "replace" ] // {
      pname = name;
      version = "0-${inputs.greenhouse.shortRev or "dirty"}";

      src = inputs.greenhouse;
      setSourceRoot = "sourceRoot=$(echo */${name})";

      postPatch = final.lib.optionalString (replace != {}) ''
        cp config.def.h config.h
        substituteInPlace config.h ${final.lib.concatStrings (final.lib.mapAttrsToList (from: to:
          " --replace-fail '\"${from}\"' '\"${to}\"'"
        ) replace)}
      '';

      makeFlags = [
        "PREFIX=$(out)"
        "CC=${final.stdenv.cc.targetPrefix}cc"
      ] ++ attrs.makeFlags or [];
    });
  };

  modifications = final: prev: {
    dwl =
      let
        inherit (final) lib;
        hex = lib.getAttrs [ "bg" "fg" "surface" "green" "red" "teal" ] outputs.palette.hex;
      in
        (prev.dwl.override {
          wlroots_0_20 = prev.wlroots_0_20.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./dwl/wlroots-clipboard.patch ];
          });
          configH = final.replaceVars ./dwl/config.h (
            lib.mapAttrs (_: c: "0x${c}ff") hex
            // lib.mapAttrs' (n: c: lib.nameValuePair "${n}Rgb" c)
              (lib.getAttrs [ "bg" "fg" "surface" "green" ] hex)
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
