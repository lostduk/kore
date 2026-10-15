{ inputs, outputs, config, lib, pkgs, utils, modulesPath, ... }:

let
  impermanence = config.kore.impermanence.enable;
  rollback = impermanence && config ? disko && config.disko.devices.disk ? main;
  wsl = config ? wsl && config.wsl.enable;

  rootDevice = config.fileSystems."/".device;
  rootUnit = "${utils.escapeSystemdPath rootDevice}.device";
in {
  imports = [
    inputs.impermanence.nixosModules.impermanence

    ( modulesPath + "/profiles/minimal.nix" )
  ];

  programs.bash.promptInit = ''
    __prompt() {
      local status=$?
      case "$TERM" in
        foot*|xterm*|tmux*|screen*)
          printf '\e]0;%s@%s %s\a' "$USER" "''${HOSTNAME%%.*}" "''${PWD/#$HOME/\~}" ;;
      esac

      local arrow='\[\e[32m\]->\[\e[0m\]'
      [ "$status" -ne 0 ] && arrow='\[\e[31m\]->\[\e[0m\]'

      local pre=""
      [ -n "''${SSH_CONNECTION:-}" ] && pre='\[\e[37m\]\h\[\e[0m\] '
      [ "$EUID" -eq 0 ] && pre="\[\e[31m\]root\[\e[0m\] $pre"

      PS1="$pre\[\e[37m\]\W\[\e[0m\] $arrow "
    }
    PROMPT_COMMAND=__prompt
  '';

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  };
  time.timeZone = lib.mkDefault "UTC";

  nix = {
    package = pkgs.nixVersions.latest;

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    settings = {
      keep-outputs = false;
      keep-derivations = false;
      auto-optimise-store = true;

      trusted-users = [ "root" "@wheel" ];
      experimental-features = [ "nix-command" "flakes" ];
    };

    registry.nixpkgs.to = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      inherit (inputs.nixpkgs) rev narHash;
    };
    nixPath = [ "nixpkgs=flake:nixpkgs" ];
  };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;

    flake = {
      setFlakeRegistry = false;
      setNixPath = false;
    };

    config = {
      allowUnfree = lib.mkForce false;
      allowBroken = lib.mkForce false;
    };
  };

  system.tools = {
    nixos-build-vms.enable = false;
    nixos-enter.enable = false;
    nixos-generate-config.enable = false;
    nixos-install.enable = false;
    nixos-option.enable = false;
  };

  networking = {
    domain = "lostduk.com";

    useDHCP = lib.mkDefault true;
    enableIPv6 = lib.mkForce false;

    firewall = {
      enable = lib.mkForce true;
      allowPing = lib.mkForce false;
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };
  };

  networking.dhcpcd.extraConfig = lib.mkIf (!wsl) "nohook resolv.conf";

  services = {
    pcscd.enable = true;

    resolved = lib.mkIf (!wsl) {
      enable = true;

      settings.Resolve = {
        DNS = [
          "194.242.2.2#dns.mullvad.net"
          "9.9.9.9#dns.quad9.net"
          "149.112.112.112#dns.quad9.net"
        ];
        FallbackDNS = [];
        Domains = [ "~." ];
        DNSOverTLS = true;
        DNSSEC = false;
      };
    };

    openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
      hostKeys = [{
        path = "${lib.optionalString impermanence "/persist"}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }];
    };
  };

  security = {
    protectKernelImage = true;

    audit = {
      enable = true;
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };

    sudo = {
      execWheelOnly = true;
      wheelNeedsPassword = lib.mkForce true;
    };

    auditd.enable = true;
    pam.sshAgentAuth.enable = true;
  };

  users = {
    mutableUsers = lib.mkForce false;

    users.root.hashedPassword = lib.mkForce "!";
  };

  boot = {
    kernelParams = [
      "slab_nomerge"
      "init_on_alloc=1"
      "init_on_free=1"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
      "vsyscall=none"
      "debugfs=off"
    ];

    kernel.sysctl = {
      "kernel.kptr_restrict" = 2;
      "kernel.dmesg_restrict" = 1;
      "kernel.printk" = "3 3 3 3";
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "kernel.sysrq" = 0;
      "kernel.perf_event_paranoid" = 3;
      "dev.tty.ldisc_autoload" = 0;
      "vm.unprivileged_userfaultfd" = 0;
      "fs.suid_dumpable" = 0;
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.protected_symlinks" = 1;
      "fs.protected_hardlinks" = 1;

      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.conf.default.accept_source_route" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    };

    blacklistedKernelModules = [
      "dccp" "sctp" "rds" "tipc" "n-hdlc" "ax25" "netrom" "x25" "rose"
      "decnet" "econet" "af_802154" "ipx" "appletalk" "psnap" "p8023"
      "p8022" "can" "atm"
      "cramfs" "freevxfs" "jffs2" "hfs" "hfsplus"
      "firewire-core" "thunderbolt" "vivid"
    ];
  };

  systemd.coredump.settings.Coredump = {
    Storage = "none";
    ProcessSizeMax = 0;
  };

  environment = {
    defaultPackages = lib.mkForce [];

    etc = lib.mkIf (!config.services.openssh.enable) (lib.mapAttrs' (name: user:
      lib.nameValuePair "ssh/authorized_keys.d/${name}" {
        mode = "0444";
        text = lib.concatLines user.openssh.authorizedKeys.keys;
      }) (lib.filterAttrs (_: user: user.openssh.authorizedKeys.keys != []) config.users.users));

    persistence."/persist" = {
      enable = impermanence;
      hideMounts = false;

      directories = [
        "/srv"
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd"
      ];
    };
  };

  programs.nano.enable = false;

  fileSystems = lib.mkIf impermanence {
    "/persist".neededForBoot = true;
  };

  system.activationScripts.persistent-dirs = lib.mkIf impermanence {
    deps = [ "users" ];
    text =
      let
        mkHomePersist = user: lib.optionalString user.createHome ''
          mkdir -p /persist${user.home}
          chown ${user.name}:${user.group} /persist${user.home}
          chmod ${user.homeMode} /persist${user.home}
        '';
      in
        lib.concatLines (map mkHomePersist (lib.attrValues config.users.users));
  };

  assertions = [{
    assertion = rollback -> config.boot.initrd.systemd.enable;
    message = "kore: root rollback needs boot.initrd.systemd.enable";
  }];

  boot.initrd = lib.mkIf rollback {
    supportedFilesystems = [ "btrfs" ];

    systemd.services.wipe-root = {
      wantedBy = [ "initrd.target" ];
      requires = [ rootUnit ];
      after = [ rootUnit ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /tmp
        MNTPOINT=$(mktemp -d)
        (
          mount ${rootDevice} "$MNTPOINT"
          trap 'umount "$MNTPOINT"' EXIT

          if [[ -e $MNTPOINT/@ ]]; then
            echo "Backing up root..."
            mkdir -p $MNTPOINT/old_roots
            mv "$MNTPOINT/@" "$MNTPOINT/old_roots/@_$(date "+%Y-%m-%-d_%H:%M:%S")"
          fi

          echo "Deleting 7+ days old roots..."
          find "$MNTPOINT/old_roots" -mindepth 1 -maxdepth 1 \
            -mtime +7 \
            -exec btrfs sub del -R {} +

          echo "Creating new root..."
          btrfs sub cre "$MNTPOINT/@"
        )
      '';
    };
  };
}
