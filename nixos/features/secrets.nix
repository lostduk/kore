{ inputs, config, lib, ... }:

let
  hostFile = ../../secrets + "/${config.networking.hostName}.yaml";
in {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops.defaultSopsFile = lib.mkIf (builtins.pathExists hostFile) hostFile;
}
