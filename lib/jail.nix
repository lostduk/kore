''
  jail_lock() {
    jail_wl="$XDG_RUNTIME_DIR/kore-$1.wayland"
    exec 9> "$XDG_RUNTIME_DIR/$1.lock"
    if ! flock -n 9; then
      echo "$1 is already running" >&2
      exit 0
    fi
  }

  jail_base() {
    local run="$XDG_RUNTIME_DIR"
    jail+=(
      --unshare-all --share-net
      --die-with-parent --new-session
      --ro-bind /nix/store /nix/store
      --ro-bind /etc /etc
      --ro-bind /run/current-system /run/current-system
      --ro-bind /run/opengl-driver /run/opengl-driver
      --ro-bind-try /run/systemd/resolve /run/systemd/resolve
      --proc /proc
      --dev /dev
      --dev-bind /dev/dri /dev/dri
      --tmpfs /tmp
      --tmpfs "$run"
      --ro-bind "$jail_wl" "$run/$WAYLAND_DISPLAY"
      --ro-bind "$run/pipewire-0" "$run/pipewire-0"
      --ro-bind "$run/pulse/native" "$run/pulse/native"
    )
  }

  jail_hardware() {
    local id="$1" mid="" dev link gpu=""

    if [ -f "$id" ] && [ ! -L "$id" ]; then
      mid="$(head -c 32 -- "$id")"
    fi
    if ! [[ $mid =~ ^[0-9a-f]{32}$ ]]; then
      mid="$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')"
      mkdir -p "$(dirname "$id")"
      rm -f -- "$id"
      printf '%s\n' "$mid" > "$id"
    fi
    exec 8<<< "$mid"
    jail+=(--ro-bind-data 8 /etc/machine-id)

    jail+=(--dir /sys --ro-bind /sys/devices/system/cpu /sys/devices/system/cpu)
    [ -d /sys/devices/system/node ] && jail+=(--ro-bind /sys/devices/system/node /sys/devices/system/node)

    for dev in /dev/dri/card* /dev/dri/renderD*; do
      [ -c "$dev" ] || continue
      link="$(readlink -f "/sys/dev/char/$(stat -c '%Hr:%Lr' "$dev")")"
      jail+=(--symlink "$link" "/sys/dev/char/$(stat -c '%Hr:%Lr' "$dev")")
      if [ -z "$gpu" ]; then
        gpu="$(readlink -f "$link/device")"
        jail+=(--ro-bind "$gpu" "$gpu" --symlink "$gpu" "/sys/bus/pci/devices/$(basename "$gpu")")
      fi
    done
  }
''
