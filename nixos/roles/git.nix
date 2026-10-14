{ inputs, config, lib, pkgs, ... }:

let
  inherit (config.kore) identities repos;
  inherit (config.networking) domain;
  root = "/srv/git";

  petal = pkgs.stdenv.mkDerivation {
    pname = "petal";
    version = "0-${inputs.greenhouse.shortRev or "dirty"}";

    src = "${inputs.greenhouse}/petal";

    buildInputs = [ pkgs.libgit2 ];

    makeFlags = [
      "PREFIX=$(out)"
      "CC=${pkgs.stdenv.cc.targetPrefix}cc"
      "GIT2INC=${lib.getDev pkgs.libgit2}/include"
      "GIT2LIB=${lib.getLib pkgs.libgit2}/lib"
    ];
  };

  petalHome = pkgs.writeTextDir ".gitconfig" (lib.generators.toGitINI {
    safe.directory = map (repo: "${root}/${repo}.git") (lib.attrNames repos);
  });

  owner = access: if access.owner != null then access.owner else lib.findFirst (_: true) "" access.write;

  acl = pkgs.writeText "kore-git-acl" (lib.concatLines (lib.concatLists (lib.mapAttrsToList (repo: access:
    map (id: "${repo} write ${id}") access.write
    ++ map (id: "${repo} read ${id}") access.read
  ) repos)));

  kore-git = pkgs.writeShellApplication {
    name = "kore-git";
    runtimeInputs = [ pkgs.git pkgs.gnugrep ];
    text = ''
      id="$1"
      cmd="''${SSH_ORIGINAL_COMMAND:-}"

      deny() {
        echo "kore-git: access denied" >&2
        exit 1
      }

      verb="''${cmd%% *}"
      case "$verb" in
        git-upload-pack | git-upload-archive) perm="read" ;;
        git-receive-pack) perm="write" ;;
        *)
          echo "kore-git: hi $id, shell access is not provided" >&2
          exit 1
          ;;
      esac

      path="''${cmd#"$verb" }"
      path="''${path#\'}"
      path="''${path%\'}"
      path="''${path#/}"
      path="''${path%/}"
      path="''${path%.git}"

      [[ "$path" =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*(/[A-Za-z0-9_][A-Za-z0-9._-]*)*$ ]] || deny

      grep -qFx "$path write $id" ${acl} \
        || { [ "$perm" = read ] && grep -qFx "$path read $id" ${acl}; } \
        || deny

      exec git-shell -c "$verb '${root}/$path.git'"
    '';
  };

  members = lib.unique (lib.concatLists (lib.mapAttrsToList (_: access: access.write ++ access.read) repos));
in {
  assertions = [{
    assertion = lib.elem "web" config.kore.currentHost.roles;
    message = "kore: the git role needs the web role for petal";
  }];

  users.groups.git = {};
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = root;
    homeMode = "750";
    createHome = true;
    shell = pkgs.bash;

    openssh.authorizedKeys.keys = lib.concatMap (id:
      map (key: ''command="${kore-git}/bin/kore-git ${id}",restrict ${key}'') (identities.${id}.sshKeys or [])
    ) members;
  };

  systemd.services.kore-git-repos = {
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "git";
      Group = "git";
    };
    path = [ pkgs.git pkgs.coreutils ];
    script = lib.concatStrings (lib.mapAttrsToList (repo: access: ''
      if [ ! -d '${root}/${repo}.git' ]; then
        mkdir -p "$(dirname '${root}/${repo}.git')"
        git init --quiet --bare --initial-branch=main '${root}/${repo}.git'
      fi
      printf '%s\n' ${lib.escapeShellArg access.description} > '${root}/${repo}.git/description'
      printf '%s\n' ${lib.escapeShellArg (owner access)} > '${root}/${repo}.git/owner'
    '') repos);
  };

  systemd.tmpfiles.rules = [ "z ${root} 0750 git git -" ];

  users.users.petal = {
    isSystemUser = true;
    group = "git";
  };

  services.fcgiwrap.instances.petal = {
    process.user = "petal";
    process.group = "git";
    socket.user = config.services.nginx.user;
    socket.group = config.services.nginx.group;
  };

  services.nginx.virtualHosts."git.${domain}" = {
    enableACME = true;
    forceSSL = true;

    locations."= /style.css".alias = "${petal}/share/petal/style.css";

    locations."/".extraConfig = ''
      fastcgi_param GATEWAY_INTERFACE CGI/1.1;
      fastcgi_param SERVER_PROTOCOL $server_protocol;
      fastcgi_param SERVER_NAME $server_name;
      fastcgi_param SERVER_PORT $server_port;
      fastcgi_param REQUEST_METHOD $request_method;
      fastcgi_param REQUEST_URI $request_uri;
      fastcgi_param QUERY_STRING $query_string;
      fastcgi_param REMOTE_ADDR $remote_addr;
      fastcgi_param HTTPS $https if_not_empty;
      fastcgi_param SCRIPT_FILENAME ${petal}/bin/petal;
      fastcgi_param SCRIPT_NAME "";
      fastcgi_param PATH_INFO $uri;
      fastcgi_param HOME ${petalHome};
      fastcgi_pass unix:${config.services.fcgiwrap.instances.petal.socket.address};
    '';
  };
}
