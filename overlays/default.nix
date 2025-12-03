{ inputs, outputs, ... }:

{
  # https://m7.rs/git/nix-config/tree/overlays/default.nix#line-13
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (_: flake:
        let
          legacyPackages = (flake.legacyPackages or {}).${final.system} or {};
          packages = (flake.packages or {}).${final.system} or {};
        in
          if legacyPackages != {} then legacyPackages else packages
      )
      inputs;
  };

  modifications = final: prev: {
    dwl = prev.dwl.overrideAttrs (oldAttrs: {
      enableXWayland = true;
      
      postPatch = ''
        cp ${./dwl_config.h} config.h
      '';
    });
  };
}
