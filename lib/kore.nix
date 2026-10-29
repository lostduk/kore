{ config, lib, kore, ... }:

let
  cfg = config.kore;
  hostname = config.networking.hostName;
  hasHome = cfg.currentHost.feats.home != [];
  hostKey = name: ../keys/hosts + "/${name}.pub";

  identityOptions = { name, ... }:
    let
      dir = ../keys/user + "/${name}";
      sshDir = dir;
      gpgFile = dir + "/gpg.asc";

      sshFiles = lib.optionals (builtins.pathExists sshDir)
        (lib.filter (lib.hasSuffix ".pub") (lib.attrNames (builtins.readDir sshDir)));
    in {
      options = with lib; {
        email = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        gpg = mkOption {
          type = types.nullOr types.str;
          default = null;
        };
        sshKeys = mkOption {
          type = types.listOf types.str;
          default = map (file: lib.fileContents (sshDir + "/${file}")) sshFiles;
        };
        gpgKey = mkOption {
          type = types.nullOr types.path;
          default = if builtins.pathExists gpgFile then gpgFile else null;
        };
        devices = mkOption {
          type = types.listOf types.str;
          default = [];
        };
      };
    };

  hostOptions = with lib; {
    system = mkOption {
      type = types.str;
    };
    stateVersion = mkOption {
      type = types.str;
    };
    feats = {
      nixos = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      home = mkOption {
        type = types.listOf types.str;
        default = [];
      };
    };
    users = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    ipv4 = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  repoOptions = with lib; {
    write = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    read = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    description = mkOption {
      type = types.str;
      default = "";
    };
    owner = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    mirror = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    private = mkOption {
      type = types.bool;
      default = false;
    };
  };

  listOptions = with lib; {
    description = mkOption {
      type = types.str;
      default = "";
    };
    owner = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    post = mkOption {
      type = types.enum [ "anyone" "subscribers" "owner" ];
      default = "subscribers";
    };
    subscribe = mkOption {
      type = types.enum [ "open" "closed" ];
      default = "open";
    };
    private = mkOption {
      type = types.bool;
      default = false;
    };
  };

  roleDomains = {
    git = "git";
    mail = "mail";
    lists = "lists";
  };

  hostNames = name: host:
    let names = [ name ] ++ map (role: roleDomains.${role}) (lib.filter (role: roleDomains ? ${role}) host.feats.nixos);
    in map (n: "${n}.${config.networking.domain}") names ++ names;
in {
  options.kore = with lib; {
    identities = mkOption {
      type = types.attrsOf (types.submodule identityOptions);
      default = {};
    };
    hosts = mkOption {
      type = types.attrsOf (types.submodule [{ options = hostOptions; }]);
      default = {};
    };
    currentHost = mkOption {
      type = types.submodule [{ options = hostOptions; }];
    };
    repos = mkOption {
      type = types.attrsOf (types.submodule [{ options = repoOptions; }]);
      default = {};
    };
    lists = mkOption {
      type = types.attrsOf (types.submodule [{ options = listOptions; }]);
      default = {};
    };

    admin = mkOption {
      type = types.str;
      default = builtins.head cfg.currentHost.users;
      readOnly = true;
    };

    mailboxes = mkOption {
      type = types.attrsOf types.str;
      default = lib.mapAttrs (_: identity: identity.email) (lib.filterAttrs (_: identity:
        identity.email != null && lib.hasSuffix "@${config.networking.domain}" identity.email
      ) cfg.identities);
      readOnly = true;
    };

    domains = mkOption {
      type = types.attrsOf types.str;
      default = lib.mapAttrs (_: sub: "${sub}.${config.networking.domain}") roleDomains;
      readOnly = true;
    };


    impermanence.enable = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = {
    kore = {
      identities = kore.identities or {};
      hosts = kore.hosts;
      currentHost = kore.hosts.${hostname};
      repos = kore.repos or {};
      lists = kore.lists or {};
    };

    assertions = map (user: {
      assertion = cfg.identities ? ${user};
      message = "kore: ${hostname} has user ${user}, but kore.nix has no identity for it";
    }) cfg.currentHost.users
    ++ lib.concatLists (lib.mapAttrsToList (repo: acl: [{
      assertion = builtins.match "[A-Za-z0-9_][A-Za-z0-9._-]*(/[A-Za-z0-9_][A-Za-z0-9._-]*)*" repo != null
        && !(lib.hasSuffix ".git" repo);
      message = "kore: repo name ${repo} is invalid";
    }] ++ map (id: {
      assertion = cfg.identities ? ${id};
      message = "kore: repo ${repo} lists ${id}, but kore.nix has no identity for it";
    }) (acl.write ++ acl.read ++ lib.optional (acl.owner != null) acl.owner)) cfg.repos)
    ++ lib.concatLists (lib.mapAttrsToList (list: opts: [{
      assertion = builtins.match "[a-z0-9][a-z0-9-]*" list != null && lib.stringLength list <= 64;
      message = "kore: list name ${list} is invalid";
    }] ++ lib.optional (opts.owner != null) {
      assertion = (cfg.identities.${opts.owner}.email or null) != null;
      message = "kore: list ${list} is owned by ${opts.owner}, but kore.nix has no identity with an email for it";
    }) cfg.lists);

    nixpkgs.hostPlatform = cfg.currentHost.system;
    system.stateVersion = cfg.currentHost.stateVersion;

    sops.defaultSopsFile = ../secrets/global.yaml;
    services.openssh.generateHostKeys = true;

    sops.secrets = lib.listToAttrs (map (user: lib.nameValuePair "users/${user}/password" {
      neededForUsers = true;
    }) cfg.currentHost.users);

    users.users = lib.listToAttrs (lib.imap0 (i: user: lib.nameValuePair user {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets."users/${user}/password".path;
      extraGroups = [ "wheel" ];

      createHome = hasHome;
      home = if hasHome then "/home/${user}" else "/var/empty";

      subUidRanges = [{ startUid = 100000 + i * 65536; count = 65536; }];
      subGidRanges = [{ startGid = 100000 + i * 65536; count = 65536; }];

      openssh.authorizedKeys.keys = cfg.identities.${user}.sshKeys or [];
    }) cfg.currentHost.users) // {
      root.openssh.authorizedKeys.keys = cfg.identities.${cfg.admin}.sshKeys;
    };

    # /etc/hosts so machines resolve each other by name.
    networking.hosts = lib.mkMerge (lib.mapAttrsToList (name: host:
      lib.optionalAttrs (host.ipv4 != null) {
        "${host.ipv4}" = hostNames name host;
      }) cfg.hosts);

    programs.ssh.knownHosts = lib.mapAttrs (name: host: {
      hostNames = hostNames name host
        ++ lib.optional (host.ipv4 != null) host.ipv4;
      publicKeyFile = hostKey name;
    }) (lib.filterAttrs (name: _: builtins.pathExists (hostKey name)) cfg.hosts);
  };
}
