{ config, lib, kore, ... }:

let
  cfg = config.kore;
  hostname = config.networking.hostName;
  hasHome = lib.elem "home" cfg.currentHost.roles;
  hostKey = name: ../../keys/hosts + "/${name}.pub";

  identityOptions = { name, ... }:
    let
      dir = ../../keys/identities + "/${name}";
      sshDir = dir + "/ssh";
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
      };
    };

  hostOptions = with lib; {
    system = mkOption {
      type = types.str;
    };
    stateVersion = mkOption {
      type = types.str;
    };
    roles = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    users = mkOption {
      type = types.listOf types.str;
      default = [];
    };
    aliases = mkOption {
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
  };

  hostNames = name: host:
    let names = [ name ] ++ host.aliases;
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
    };

    assertions = map (user: {
      assertion = cfg.identities ? ${user};
      message = "kore: ${hostname} has user ${user}, but kore.json has no identity for it";
    }) cfg.currentHost.users
    ++ lib.concatLists (lib.mapAttrsToList (repo: acl: [{
      assertion = builtins.match "[A-Za-z0-9_][A-Za-z0-9._-]*(/[A-Za-z0-9_][A-Za-z0-9._-]*)*" repo != null
        && !(lib.hasSuffix ".git" repo);
      message = "kore: repo name ${repo} is invalid";
    }] ++ map (id: {
      assertion = cfg.identities ? ${id};
      message = "kore: repo ${repo} lists ${id}, but kore.json has no identity for it";
    }) (acl.write ++ acl.read ++ lib.optional (acl.owner != null) acl.owner)) cfg.repos);

    nixpkgs.hostPlatform = cfg.currentHost.system;
    system.stateVersion = cfg.currentHost.stateVersion;

    users.users = lib.listToAttrs (lib.imap0 (i: user: lib.nameValuePair user {
      isNormalUser = true;
      password = "tmp";
      extraGroups = [ "wheel" ];

      createHome = hasHome;
      home = if hasHome then "/home/${user}" else "/var/empty";

      subUidRanges = [{ startUid = 100000 + i * 65536; count = 65536; }];
      subGidRanges = [{ startGid = 100000 + i * 65536; count = 65536; }];

      openssh.authorizedKeys.keys = cfg.identities.${user}.sshKeys or [];
    }) cfg.currentHost.users);

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
