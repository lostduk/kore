{ config, lib, ... }:

let
  inherit (config.kore) admin;
in {
  security.acme = {
    acceptTerms = true;
    defaults.email = config.kore.identities.${admin}.email;
  };

  services.nginx = {
    enable = true;

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    appendHttpConfig = ''
      add_header Strict-Transport-Security "max-age=63072000" always;
    '';

    virtualHosts."_" = {
      default = true;
      rejectSSL = true;
      extraConfig = "return 444;";
    };
  };

  systemd.services = lib.mapAttrs' (name: _: lib.nameValuePair "fcgiwrap-${name}" {
    serviceConfig = {
      CapabilityBoundingSet = "";
      IPAddressDeny = "any";
      LockPersonality = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" "~@privileged" ];
    };
  }) config.services.fcgiwrap.instances;

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  environment.persistence."/persist".directories = [ "/var/lib/acme" ];
}
