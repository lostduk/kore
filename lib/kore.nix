{ config, lib, kore, ... }:

let
  cfg = config.kore;
  hostname = config.networking.hostName;
  hasHome = cfg.currentHost.feats.home != [];
  hostKey = name: ../keys/hosts + "/${name}.pub";

  opt = type: default: lib.mkOption { inherit type default; };
  roles = [ "git" "mail" "lists" ];

  identityOptions = { name, ... }:
    let
      dir = ../keys/user + "/${name}";
      gpgFile = dir + "/gpg.asc";

      sshFiles = lib.optionals (builtins.pathExists dir)
        (lib.filter (lib.hasSuffix ".pub") (lib.attrNames (builtins.readDir dir)));
    in {
      options = with lib.types; {
        email = opt (nullOr str) null;
        gpg = opt (nullOr str) null;
        sshKeys = opt (listOf str) (map (file: lib.fileContents (dir + "/${file}")) sshFiles);
        gpgKey = opt (nullOr path) (if builtins.pathExists gpgFile then gpgFile else null);
        devices = opt (listOf str) [];
      };
    };

  hostOptions = with lib.types; {
    system = lib.mkOption { type = str; };
    stateVersion = lib.mkOption { type = str; };
    feats.nixos = opt (listOf str) [];
    feats.home = opt (listOf str) [];
    users = opt (listOf str) [];
    ipv4 = opt (nullOr str) null;
  };

  repoOptions = with lib.types; {
    write = opt (listOf str) [];
    read = opt (listOf str) [];
    description = opt str "";
    owner = opt (nullOr str) null;
    mirror = opt (nullOr str) null;
    private = opt bool false;
  };

  listOptions = with lib.types; {
    description = opt str "";
    owner = opt (nullOr str) null;
    post = opt (enum [ "anyone" "subscribers" "owner" ]) "subscribers";
    subscribe = opt (enum [ "open" "closed" ]) "open";
    private = opt bool false;
  };

  hostNames = name: host:
    let names = [ name ] ++ lib.intersectLists roles host.feats.nixos;
    in map (n: "${n}.${config.networking.domain}") names ++ names;
in {
  options.kore = with lib; {
    identities = opt (types.attrsOf (types.submodule identityOptions)) {};
    hosts = opt (types.attrsOf (types.submodule { options = hostOptions; })) {};
    currentHost = mkOption { type = types.submodule { options = hostOptions; }; };
    repos = opt (types.attrsOf (types.submodule { options = repoOptions; })) {};
    lists = opt (types.attrsOf (types.submodule { options = listOptions; })) {};
    requires = opt (types.attrsOf (types.listOf types.str)) {};

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
      default = lib.genAttrs roles (role: "${role}.${config.networking.domain}");
      readOnly = true;
    };


    impermanence.enable = opt types.bool true;
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
    ++ lib.concatLists (lib.mapAttrsToList (feat: deps: map (dep: {
      assertion = lib.elem dep cfg.currentHost.feats.nixos;
      message = "kore: ${feat} needs ${dep}, add \"${dep}\" to hosts.${hostname}.feats.nixos in kore.nix";
    }) deps) cfg.requires)
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
