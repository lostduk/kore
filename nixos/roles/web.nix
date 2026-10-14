{ config, pkgs, ... }:

let
  inherit (config.networking) domain;
  admin = builtins.head config.kore.currentHost.users;
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

    virtualHosts.${domain} = {
      enableACME = true;
      forceSSL = true;

      root = pkgs.writeTextDir "index.html" ''
        <!doctype html>
        <html lang="en">
        <meta charset="utf-8">
        <title>${domain}</title>
        <p>soon</p>
        </html>
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
  environment.persistence."/persist".directories = [ "/var/lib/acme" ];
}
