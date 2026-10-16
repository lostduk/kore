{ inputs, config, lib, ... }:

let
  hostFile = ../../secrets + "/${config.networking.hostName}.yaml";
in {
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.kore.secrets.enable = lib.mkOption {
    type = lib.types.bool;
    default = builtins.pathExists hostFile;
    readOnly = true;
  };

  config = {
    sops.defaultSopsFile = lib.mkIf config.kore.secrets.enable hostFile;
    services.openssh.generateHostKeys = true;
  };
}
