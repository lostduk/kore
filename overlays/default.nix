{ inputs, ... }:

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
    dwl = prev.dwl.override { configH = ./dwl_config.h; };
  };
}
