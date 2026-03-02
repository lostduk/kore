{ inputs, outputs, config, pkgs, lib, ... }:

let
  roleName = "workstation";
  roleEnabled = lib.elem roleName config.kore.currentHost.roles;
in {
  imports = [ inputs.home-manager.nixosModules.home-manager  ];

  config = lib.mkMerge [{} (lib.mkIf roleEnabled {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs outputs; };

      users.lostduk = outputs.homeConfigurations.${config.networking.hostName};
    };

    programs.fuse.userAllowOther = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
      configPackages = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];

      wlr.enable = true;

      config.common = {
        default = [ "wlr" ];
      };
    };

    system.activationScripts.persistent-dirs.text =
      let
        mkHomePersist = user: lib.optionalString user.createHome ''
          mkdir -p /persist/${user.home}
          chown ${user.name}:${user.group} /persist/${user.home}
          chmod ${user.homeMode} /persist/${user.home}
        '';
        users = lib.attrValues config.users.users;
      in
        lib.concatLines (map mkHomePersist users);

    fonts = {
      enableDefaultPackages = false;

      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji

        #(nerdfonts.override { fonts = [ "ComicShannsMono" ]; })
        nerd-fonts.comic-shanns-mono
      ];

      fontconfig = {
        hinting.autohint = true;

        defaultFonts = {
          serif = [ "Noto Serif" "Noto Color Emoji" ];
          sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
          monospace = [ "ComicShannsMono Nerd Font" "Noto Color Emoji" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };
    };

    services = {
      udisks2.enable = true;

      pipewire = {
        enable = true;

        alsa.enable = true;
        alsa.support32Bit = true;

        pulse.enable = true;
        jack.enable = true;

        wireplumber = {
          enable = true;

          # https://github.com/NixOS/nixpkgs/pull/292115
          extraConfig."alsa-lowlatency" = {
            "monitor.alsa.rules" = [{
              matches = [{ "node.name" = "~alsa_output.*"; }];

              actions.update-props = {
                "audio.format" = "S32LE";
                "audio.rate" = "96000";
                "api.alsa.period-size" = 2;
              };
            }];
          };
        };

        extraConfig.pipewire."92-low-latency" = {
          context = {
            properties.default.clock = {
              rate = 48000;
              quantum = 64;
            };

            modules = [{
              name = "libpipewire-module-protocol-pulse";

              args.pulse = {
                min = {
                  req = "64/48000";
                  quantum = "64/48000";
                  frag = "64/48000";
                };

                default.req = "64/48000";
              };
            }];
          };
          
          stream.properties = {
            node.latency = "64/48000";
            resample.quality = 1;
          };
        };
      };
    };
  })];
}

