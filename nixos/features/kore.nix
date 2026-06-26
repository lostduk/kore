{ config, lib, kore, ... }:

let
  hostOptions = with lib; {
    system = mkOption {
      type = types.str;
    };
    ipv4 = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    roles = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
in {
  options.kore = with lib; {
    hosts = mkOption {
      type = types.attrsOf (types.submodule [{ options = hostOptions; }]);
      default = {};
    };
    currentHost = mkOption {
      type = types.submodule [{ options = hostOptions; }];
    };
  };
  config = {
    warnings = lib.optional (!(kore.hosts ? ${config.networking.hostName}))
      "no configuration for ${config.networking.hostName} found";

    kore = {
      hosts = kore.hosts;
      currentHost = kore.hosts.${config.networking.hostName};
    };

    # /etc/hosts so machines resolve each other by name; placeholder
    # 0.0.0.0 addresses are skipped.
    networking.hosts = lib.mkMerge (lib.mapAttrsToList (name: host:
      lib.optionalAttrs (host.ipv4 != null && host.ipv4 != "0.0.0.0") {
        "${host.ipv4}" = [ "${name}.${config.networking.domain}" name ];
      }) kore.hosts);
  };
}
