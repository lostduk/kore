{ config, lib, pkgs, ... }:

let
  inherit (config.kore) identities repos;
  inherit (config.networking) domain;
  root = "/srv/git";

  petal = pkgs.greenhouse "petal" {
    buildInputs = [ pkgs.libgit2 ];
    makeFlags = [
      "GIT2INC=${lib.getDev pkgs.libgit2}/include"
      "GIT2LIB=${lib.getLib pkgs.libgit2}/lib"
    ];
  };

  petalHome = pkgs.writeTextDir ".gitconfig" (lib.generators.toGitINI {
    safe.directory = map (repo: "${root}/${repo}.git") (lib.attrNames repos);
  });

  mirrorKey = "${root}/.ssh/mirror";
  mirrors = lib.any (access: access.mirror != null) (lib.attrValues repos);

  mirrorHook = pkgs.writeShellScript "kore-git-mirror" ''
    cat > /dev/null
    url=$(${pkgs.git}/bin/git config --get kore.mirror) || exit 0
    export GIT_SSH_COMMAND="${pkgs.openssh}/bin/ssh -i ${mirrorKey} -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes"
    if ${pkgs.coreutils}/bin/timeout 60 ${pkgs.git}/bin/git push --mirror --quiet "$url"; then
      echo "kore-git: mirrored to $url"
    else
      echo "kore-git: mirror to $url failed" >&2
    fi
  '';

  fastcgi = ''
    fastcgi_param GATEWAY_INTERFACE CGI/1.1;
    fastcgi_param SERVER_PROTOCOL $server_protocol;
    fastcgi_param SERVER_NAME $server_name;
    fastcgi_param SERVER_PORT $server_port;
    fastcgi_param REQUEST_METHOD $request_method;
    fastcgi_param REQUEST_URI $request_uri;
    fastcgi_param QUERY_STRING $query_string;
    fastcgi_param CONTENT_TYPE $content_type;
    fastcgi_param CONTENT_LENGTH $content_length;
    fastcgi_param REMOTE_ADDR $remote_addr;
    fastcgi_param HTTPS $https if_not_empty;
    fastcgi_param HOME ${petalHome};
    fastcgi_pass unix:${config.services.fcgiwrap.instances.petal.socket.address};
  '';

  owner = access: if access.owner != null then access.owner else lib.findFirst (_: true) "" access.write;

  acl = pkgs.writeText "hedge-acl" (lib.concatLines (lib.concatLists (lib.mapAttrsToList (repo: access:
    map (id: "${repo} write ${id}") access.write
    ++ map (id: "${repo} read ${id}") access.read
  ) repos)));

  hedge = pkgs.greenhouse "hedge" {
    replace = {
      "/srv/git" = root;
      "/etc/hedge/acl" = "${acl}";
      "git-shell" = "${pkgs.git}/bin/git-shell";
    };
  };

  petalCgi = pkgs.writeShellScript "petal-cgi" ''
    ulimit -t 10
    exec ${petal}/bin/petal
  '';

  members = lib.unique (lib.concatLists (lib.mapAttrsToList (_: access: access.write ++ access.read) repos));
in {
  kore.requires.git = [ "nginx" ];

  users.groups.git = {};
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = root;
    homeMode = "750";
    createHome = true;
    shell = pkgs.bash;

    openssh.authorizedKeys.keys = lib.concatMap (id:
      map (key: ''command="${hedge}/bin/hedge ${id}",restrict ${key}'') (identities.${id}.sshKeys or [])
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
    path = [ pkgs.git pkgs.coreutils pkgs.openssh ];
    script = lib.optionalString mirrors ''
      if [ ! -f '${mirrorKey}' ]; then
        mkdir -p -m 700 '${root}/.ssh'
        ssh-keygen -q -t ed25519 -N "" -C "git@${config.networking.hostName} mirror" -f '${mirrorKey}'
      fi
    '' + lib.concatStrings (lib.mapAttrsToList (repo: access: ''
      if [ ! -d '${root}/${repo}.git' ]; then
        mkdir -p "$(dirname '${root}/${repo}.git')"
        git init --quiet --bare --initial-branch=main '${root}/${repo}.git'
      fi
      printf '%s\n' ${lib.escapeShellArg access.description} > '${root}/${repo}.git/description'
      printf '%s\n' ${lib.escapeShellArg (owner access)} > '${root}/${repo}.git/owner'
      ln -sfn ${mirrorHook} '${root}/${repo}.git/hooks/post-receive'
      ${if access.mirror != null
        then "git -C '${root}/${repo}.git' config kore.mirror ${lib.escapeShellArg access.mirror}"
        else "git -C '${root}/${repo}.git' config --unset kore.mirror || true"}
      ${if access.private
        then "rm -f '${root}/${repo}.git/git-daemon-export-ok'"
        else "touch '${root}/${repo}.git/git-daemon-export-ok'"}
    '') repos);
  };

  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  systemd.tmpfiles.rules = [ "z ${root} 0750 git git -" ];

  users.users.petal = {
    isSystemUser = true;
    group = "git";
  };

  services.fcgiwrap.instances.petal = {
    process.user = "petal";
    process.group = "git";
    process.prefork = 3;
    socket.user = config.services.nginx.user;
    socket.group = config.services.nginx.group;
  };

  services.nginx.virtualHosts.${config.kore.domains.git} = {
    enableACME = true;
    forceSSL = true;

    locations."= /style.css".alias = "${petal}/share/petal/style.css";
    locations."= /icon.svg".alias = "${petal}/share/petal/icon.svg";

    locations."/".extraConfig = fastcgi + ''
      fastcgi_param SCRIPT_FILENAME ${petalCgi};
      fastcgi_param SCRIPT_NAME "";
      fastcgi_param PATH_INFO $uri;
    '';

    locations."~ ^/(.+\\.git/(?:info/refs|git-upload-pack))$".extraConfig = ''
      if ($arg_service = git-receive-pack) {
        return 403;
      }
    '' + fastcgi + ''
      fastcgi_param SCRIPT_FILENAME ${pkgs.git}/libexec/git-core/git-http-backend;
      fastcgi_param PATH_INFO /$1;
      fastcgi_param GIT_PROJECT_ROOT ${root};
    '';
  };
}
