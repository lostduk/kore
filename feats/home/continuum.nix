{ config, lib, pkgs, outputs, ... }:

let
  dataDir = "${config.xdg.dataHome}/continuum";
  persistDir = lib.removePrefix "${config.home.homeDirectory}/" dataDir;

  volt = pkgs.fetchurl {
    url = "https://cdn.azula.wtf/downloads/20261019-20ebbac43/volt-linux";
    hash = "sha256-JKMgfiMPISebi+HTGmuTwCZVkGcl+3FVKeNeTvUidCU=";
  };

  libs64 = with pkgs; [
    stdenv.cc.cc.lib zlib
    libx11 libxext libxi libxrandr libxrender libxfixes libxinerama libxxf86vm libxcursor libxcb
    libglvnd vulkan-loader wayland
    freetype fontconfig.lib gnutls krb5.lib
    dbus.lib systemdLibs libusb1
    libpulseaudio alsa-lib
    webkitgtk_4_1 libsoup_3 gtk3 glib cairo gdk-pixbuf sqlite
  ];

  libs32 = with pkgs.pkgsi686Linux; [
    stdenv.cc.cc.lib zlib
    libx11 libxext libxi libxrandr libxrender libxfixes libxinerama libxxf86vm libxcursor libxcb
    gnutls krb5.lib
  ];

  # Wine bug (still unfixed upstream, see wine/wine!7316): without 32-bit freetype, get_text_metr_size()
  # in dlls/win32u/sysparams.c leaves its TEXTMETRICW uninitialized and the garbage is saved as
  # CaptionHeight/MenuHeight (e.g. 43182830), breaking every window. These 13 bytes make a failed
  # measurement report tmHeight = -1, so the registry values are kept.
  win32u = {
    file = "files/lib/wine/i386-unix/win32u.so";
    original = "383249bb910b0a24f79da92bc7c45d361356449c855038071bc538ccc56c6126";
    patched = "f415cf11c72b32e5bcfd7c843baa49e8ca2ad37c21480d4c08f289bd49b40cd7";
    bytes = {
      "1167886" = ''\x74\x61'';
      "1167985" = ''\x8b\x45\x0c\x83\x08\xff\x83\x60\x10\x00\xeb\xeb'';
    };
  };

  gio = [ "${pkgs.dconf.lib}/lib/gio/modules" "${pkgs.glib-networking}/lib/gio/modules" ];
  schemas = [ pkgs.gsettings-desktop-schemas pkgs.gtk3 ];

  trim = [
    "files/share/wine/mono"
    "files/share/wine/gecko"
    "files/share/espeak-ng-data"
    "files/share/libtashkeel_model.ort"
    "files/share/xalia"
  ];

  continuum = pkgs.writeShellApplication {
    name = "continuum";
    runtimeInputs = with pkgs; [ bubblewrap coreutils diffutils jq util-linux ];
    excludeShellChecks = [ "SC2016" ];
    text = ''
      run="$XDG_RUNTIME_DIR"
      x="/tmp/.X11-unix/X''${DISPLAY#:}"

      exec 9> "$run/continuum.lock"
      if ! flock -n 9; then
        echo "continuum is already running" >&2
        exit 0
      fi

      launcher="${dataDir}/.local/share/continuum-launcher"
      bin="${dataDir}/.local/share/volt/volt-linux"
      mkdir -p "$(dirname "$bin")"
      cmp -s ${volt} "$bin" || install -m755 ${volt} "$bin"

      for runtime in "$launcher"/runtime/continuum/*/; do
        rm -rf ${lib.concatMapStringsSep " " (p: ''"$runtime"${p}'') trim}

        so="$runtime"${win32u.file}
        [ -f "$so" ] || continue
        case "$(sha256sum < "$so" | cut -d' ' -f1)" in
          ${win32u.original})
            rm -f "$so.new"
            cp "$so" "$so.new"
            chmod u+w "$so.new"
            ${lib.concatStrings (lib.mapAttrsToList (offset: bytes: ''
            printf '${bytes}' | dd of="$so.new" bs=1 seek=${offset} conv=notrunc status=none
            '') win32u.bytes)}
            if [ "$(sha256sum < "$so.new" | cut -d' ' -f1)" = ${win32u.patched} ]; then
              chmod --reference="$so" "$so.new"
              mv "$so.new" "$so"
            else
              rm -f "$so.new"
              echo "continuum: patching $so failed, window metrics may break without 32-bit freetype" >&2
            fi
            ;;
          ${win32u.patched}) ;;
          *) echo "continuum: unknown $so, window metrics patch not applied" >&2 ;;
        esac
      done

      volt="${dataDir}/.config/volt-linux/client-settings.json"
      if [ -f "$volt" ]; then
        jq --slurpfile theme ${./continuum/volt-dark.json} '. + $theme[0]' "$volt" > "$volt.new"
        chmod --reference="$volt" "$volt.new"
        mv "$volt.new" "$volt"
      fi

      launcher="$HOME/.local/share/continuum-launcher"

      ${outputs.jail}
      jail=()
      jail_hardware "${dataDir}/.machine-id"

      exec bwrap \
        --unshare-all --share-net \
        --die-with-parent --new-session \
        --ro-bind /nix/store /nix/store \
        --ro-bind /etc /etc \
        --ro-bind /run/current-system /run/current-system \
        --ro-bind /run/opengl-driver /run/opengl-driver \
        --ro-bind-try /run/systemd/resolve /run/systemd/resolve \
        "''${jail[@]}" \
        --proc /proc \
        --dev /dev \
        --tmpfs /dev/shm \
        --dev-bind /dev/dri /dev/dri \
        --tmpfs /tmp \
        --ro-bind "$x" "$x" \
        --ro-bind ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 \
        --ro-bind ${pkgs.pkgsi686Linux.glibc}/lib/ld-linux.so.2 /lib/ld-linux.so.2 \
        --bind "${dataDir}" "$HOME" \
        --tmpfs "$run" \
        --ro-bind "$run/$WAYLAND_DISPLAY" "$run/$WAYLAND_DISPLAY" \
        --ro-bind "$run/pipewire-0" "$run/pipewire-0" \
        --ro-bind "$run/pulse/native" "$run/pulse/native" \
        --unsetenv DBUS_SESSION_BUS_ADDRESS \
        --unsetenv SSH_AUTH_SOCK \
        --unsetenv GPG_AGENT_INFO \
        --setenv LD_LIBRARY_PATH "${lib.makeLibraryPath (libs64 ++ libs32)}" \
        --setenv WINEDLLOVERRIDES "mscoree=d;mshtml=d" \
        --setenv GIO_EXTRA_MODULES "${lib.concatStringsSep ":" gio}" \
        --setenv GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
        --setenv XDG_DATA_DIRS "${lib.concatMapStringsSep ":" (p: "${p}/share/gsettings-schemas/${p.name}") schemas}:''${XDG_DATA_DIRS:-/run/current-system/sw/share}" \
        ${pkgs.bash}/bin/bash -c 'ws="$1" pfx="$2"; shift 2; "$@"; [ -x "$ws" ] && WINEPREFIX="$pfx" "$ws" -w; true' bash \
        "$launcher/runtime/continuum/current/files/bin/wineserver" \
        "$launcher/prefix/pfx" \
        "$HOME/.local/share/volt/volt-linux" "$@"
    '';
  };
in {
  home.packages = [ continuum ];

  home.persistence."/persist".directories = [ persistDir ];
}
