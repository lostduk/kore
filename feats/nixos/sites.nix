{ inputs, config, lib, pkgs, ... }:

let
  src = inputs.sites;

  domains = lib.attrNames (lib.filterAttrs (name: type:
    type == "directory" && builtins.pathExists "${src}/${name}/template.html"
  ) (builtins.readDir src));

  sites = pkgs.stdenvNoCC.mkDerivation {
    pname = "sites";
    version = "0-${inputs.sites.shortRev or "dirty"}";

    inherit src;

    nativeBuildInputs = [ pkgs.lowdown ];

    postPatch = "patchShebangs page";

    installPhase = ''
      runHook preInstall
      cp -r out $out
      runHook postInstall
    '';
  };
in {
  kore.requires.sites = [ "nginx" ];

  services.nginx.virtualHosts = lib.genAttrs domains (domain: {
    enableACME = true;
    forceSSL = true;
    root = "${sites}/${domain}";
  });
}
