{ config, lib, pkgs, outputs, ... }:

let
  inherit (outputs.palette) colors ramp;

  vesktop = pkgs.vesktop.override { withSystemVencord = true; };

  configDir = "${config.xdg.configHome}/vesktop";
  downloads = config.xdg.userDirs.download;

  jail = pkgs.writeShellApplication {
    name = "vesktop";
    runtimeInputs = with pkgs; [ bubblewrap xdg-dbus-proxy coreutils util-linux ];
    text = ''
      ${outputs.jail}
      jail_lock vesktop

      run="$XDG_RUNTIME_DIR"
      bus="$(mktemp -u "$run/vesktop-bus.XXXXXX")"

      xdg-dbus-proxy "$DBUS_SESSION_BUS_ADDRESS" "$bus" --filter \
        --talk=org.freedesktop.portal.Desktop \
        --talk=org.freedesktop.Notifications &
      proxy=$!
      trap 'kill "$proxy" 2>/dev/null; rm -f "$bus"' EXIT
      while [ ! -S "$bus" ]; do
        kill -0 "$proxy" 2>/dev/null || { echo "vesktop: xdg-dbus-proxy failed" >&2; exit 1; }
        sleep 0.05
      done

      mkdir -p "${configDir}" "${downloads}"

      jail=()
      jail_base
      jail_hardware "${configDir}/machine-id"

      bwrap \
        "''${jail[@]}" \
        --tmpfs /home \
        --bind "${configDir}" "${configDir}" \
        --bind "${downloads}" "${downloads}" \
        --bind "$bus" "$run/bus" \
        --setenv DBUS_SESSION_BUS_ADDRESS "unix:path=$run/bus" \
        ${lib.getExe vesktop} --ozone-platform-hint=auto "$@"
    '';
  };

  midnight = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/refact0r/midnight-discord/0377a92073a9ea7c25f707437482353de295c2e8/build/midnight.css";
    hash = "sha256-ko/iJ59EwcPUS69+lApnwocx28YIjHeKd6k1pJA2suI=";
  };

  palette = pkgs.writeText "garden-palette.css" ''
    :root {
      container-name: root;

      --font-code: "Fantasque Sans Mono", monospace;

      --text-0: ${colors.bg};
      --text-1: ${colors.fg};
      --text-2: ${colors.fg};
      --text-3: ${ramp.blossom};
      --text-4: ${colors.dim};
      --text-5: ${ramp.teal};

      --bg-1: ${colors.surface};
      --bg-2: color-mix(in srgb, ${colors.bgAlt}, ${colors.surface});
      --bg-3: ${colors.bgAlt};
      --bg-4: ${colors.bg};
      --hover: color-mix(in srgb, ${colors.green} 10%, transparent);
      --active: color-mix(in srgb, ${colors.green} 18%, transparent);
      --active-2: color-mix(in srgb, ${colors.green} 26%, transparent);
      --message-hover: color-mix(in srgb, ${colors.bgAlt} 60%, transparent);

      --accent-1: ${colors.green};
      --accent-2: ${colors.green};
      --accent-3: ${colors.green};
      --accent-4: ${ramp.sage};
      --accent-5: ${ramp.moss};
      --accent-new: ${colors.red};

      --online: ${colors.green};
      --dnd: ${colors.red};
      --idle: ${colors.yellow};
      --streaming: ${colors.magenta};
      --offline: ${colors.dim};
    }
  '';

  theme = pkgs.runCommand "garden.css" { } ''
    {
      printf '/**\n * @name garden\n * @description palette.nix over the colors module of midnight-discord (MIT, refact0r)\n */\n'
      sed -n '/^\/\* colors\.css \*\//,/^\/\* dms-button\.css \*\//p' ${midnight} | sed '$d'
      cat ${palette}
    } > "$out"
    ! grep -nE "@import|url\\(.https?:" "$out"
  '';
in {
  assertions = [{
    assertion = downloads != config.home.homeDirectory;
    message = "vesktop: xdg.userDirs.download must not be $HOME, the jail would expose the whole home";
  }];

  home.packages = [ jail ];

  programs.vesktop = {
    enable = true;
    package = null;

    settings = {
      discordBranch = "stable";
      checkUpdates = false;
      arRPC = false;
      tray = false;
      minimizeToTray = false;
      hardwareAcceleration = true;
      splashTheming = true;
      splashBackground = colors.bg;
      splashColor = colors.fg;
      staticTitle = true;
      disableMinSize = true;
    };

    vencord = {
      themes.garden = theme;

      settings = {
        autoUpdate = false;
        autoUpdateNotification = false;
        notifyAboutUpdates = false;
        enabledThemes = [ "garden.css" ];

        plugins = {
          NoTrack = {
            enabled = true;
            disableAnalytics = true;
          };
          ClearURLs.enabled = true;
          AnonymiseFileNames.enabled = true;
        };
      };
    };
  };

  home.activation.vesktopState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    state="${configDir}/state.json"
    if [ ! -e "$state" ]; then
      run mkdir -p "${configDir}"
      echo '{"firstLaunch":false}' > "$state"
    fi
  '';

  home.persistence."/persist".directories = [ ".config/vesktop" ];
}
