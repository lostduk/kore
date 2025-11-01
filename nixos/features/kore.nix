{ config, lib, ... }:

let
  hostOptions = with lib; {
    ipv4 = mkOption {
      type = types.str;
      default = null;
    };
    roles = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
    };
  };
in {
  options.kore = with lib; {
    hosts = mkOption {
      type = types.attrsOf (types.submodule [{ options = hostOptions; }]);
      default = null;
    };
    currentHost = mkOption {
      type = types.submodule [{ options = hostOptions; }];
      default = null;
    };
  };
  config = {
    warnings = lib.optional (!(config.kore.hosts ? ${config.networking.hostName}))
      "no configuration for ${config.networking.hostName} found";

    # TMP
    kore = {
      hosts = {
        sunflower = {
          ipv4 = "0.0.0.0";
          roles = [ "workstation" ];
        };
      };
      currentHost = config.kore.hosts.${config.networking.hostName};
    };
  };
}
