# shellcheck shell=bash
echo "[nix2gpu] Container initialization starting..."

# // critical // runtime directories
mkdir -p /tmp /var/tmp /run /run/sshd /var/log /var/empty
chmod 1777 /tmp /var/tmp
chmod 755 /run/sshd
export TMPDIR=/tmp
export NIX_BUILD_TOP=/tmp

# // devices // userspace networking
mkdir -p /dev/net
[ ! -c /dev/net/tun ] && mknod /dev/net/tun c 10 200 && chmod 0666 /dev/net/tun

# // ldconfig // regenerate cache with NVIDIA libs
if [ -d /lib/x86_64-linux-gnu ] && [ "$(ls -A /lib/x86_64-linux-gnu/*.so* 2>/dev/null)" ]; then
  echo "[nix2gpu] Found NVIDIA libraries, updating ld cache..."

  # Create symlinks for common library names
  for lib in /lib/x86_64-linux-gnu/*.so.*; do
    if [[ -f $lib ]]; then
      base=$(basename "$lib" | sed 's/\.so\..*//')
      ln -sf "$lib" "/lib/x86_64-linux-gnu/$base.so.1" 2>/dev/null || true
      ln -sf "$lib" "/lib/x86_64-linux-gnu/$base.so" 2>/dev/null || true
    fi
  done

  # Add Nix CUDA paths too
  for cuda_path in /nix/store/*-cuda*/lib; do
    [ -d "$cuda_path" ] && echo "$cuda_path" >>/etc/ld.so.conf.d/nix-cuda.conf
  done

  # Regenerate cache
  ldconfig 2>/dev/null || true

  # Update LD_LIBRARY_PATH for immediate use
  export LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib:${LD_LIBRARY_PATH:-}"
fi

# // dynamic // shadow file
if [ ! -f /etc/shadow ]; then
  cp /nix/store/*/etc/shadow /etc/shadow
  chmod 0640 /etc/shadow
fi

# // root // password
if [ -n "${ROOT_PASSWORD:-}" ]; then
  echo "[nix2gpu] Setting root password..."
  echo "root:$ROOT_PASSWORD" | chpasswd
else
  echo "[nix2gpu] Enabling passwordless root..."
  /run/current-system/sw/bin/passwd -d root
fi

export HOME="/root"

# // ssh // keys
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -n "${SSH_PUBLIC_KEYS:-}" ]; then
  echo "$SSH_PUBLIC_KEYS" >"$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi

# // nvidia-smi // validation
if [ -e /usr/bin/nvidia-smi ]; then
  echo "[nix2gpu] Testing nvidia-smi..."

  # First check if it needs patching
  if ! /usr/bin/nvidia-smi --version &>/dev/null; then
    echo "[nix2gpu] Patching nvidia-smi..."

    # Find the correct interpreter
    INTERP=$(find /nix/store -name "ld-linux-x86-64.so.2" -type f | head -1)
    ([ -n "$INTERP" ] && patchelf --set-interpreter "$INTERP" /usr/bin/nvidia-smi 2>/dev/null) || true

    # Set rpath to include the ACTUAL library locations
    patchelf --set-rpath "/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib" /usr/bin/nvidia-smi 2>/dev/null || true
  fi

  if /usr/bin/nvidia-smi &>/dev/null; then
    echo "[nix2gpu] GPU ready: $(/usr/bin/nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
  else
    echo "[nix2gpu] Warning: nvidia-smi not functional"
    # Debug info
    echo "[nix2gpu] Library dependencies:"
    ldd /usr/bin/nvidia-smi 2>&1 | head -10 || true
    echo "[nix2gpu] Available NVIDIA libraries:"
    printf '%s\n' /lib/x86_64-linux-gnu/libnvidia* 2>/dev/null | head -5
  fi
fi

for type in rsa ed25519; do
  key="/etc/ssh/ssh_host_${type}_key"
  [ ! -f "$key" ] && ssh-keygen -t "$type" -f "$key" -N "" >/dev/null 2>&1
done

# // ssh // daemon
echo "[nix2gpu] starting ssh daemon..."
# Gets resholved to the absolute path
sshd -t || exit 1
sshd -D -e &

export XDG_DATA_HOME="$HOME/.local/share"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="/run/user/$UID"
export XDG_BIN_HOME="$HOME/.local/bin"

# // config // extra startup script
echo "[nix2gpu] running extra startup script..."
