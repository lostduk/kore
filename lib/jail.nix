''
  jail_hardware() {
    local id="$1" dev link gpu=""

    if [ ! -s "$id" ]; then
      mkdir -p "$(dirname "$id")"
      head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$id"
      echo >> "$id"
    fi
    jail+=(--ro-bind "$id" /etc/machine-id)

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
