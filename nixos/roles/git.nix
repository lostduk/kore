{ config, lib, pkgs, ... }:

let
  inherit (config.kore) identities repos;
  root = "/srv/git";

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
  users.groups.git = {};
  users.users.git = {
    isSystemUser = true;
    group = "git";
    home = root;
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
    script = lib.concatMapStrings (repo: ''
      if [ ! -d '${root}/${repo}.git' ]; then
        mkdir -p "$(dirname '${root}/${repo}.git')"
        git init --quiet --bare --initial-branch=main '${root}/${repo}.git'
      fi
    '') (lib.attrNames repos);
  };
}
