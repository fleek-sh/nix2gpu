# shellcheck shell=bash

set -euo pipefail

gum log --level debug "Container initialization starting..."

export HOME="/root"

# section 1 // runtime directories

gum log --level debug "Writing runtime directories"
mkdir -p /tmp /var/tmp /run /run/sshd /var/log /var/empty /var/empty/sshd
chmod a+rwx,+t /tmp /var/tmp
chmod u=rwx,g=rx,o=rx /run/sshd
chmod u=rwx,g=rx,o=rx /var/empty
chmod u=rwx,g=,o= /var/empty/sshd

# section 2 // environment variables

gum log --level debug "Setting up environment"
export TMPDIR=/tmp
export NIX_BUILD_TOP=/tmp

# section 3 // network device setup

gum log --level debug "Enabling userspace networking"
mkdir -p /dev/net

if [ -c /dev/net/tun ]; then
  if ! (exec 3<>/dev/net/tun) 2>/dev/null; then
    gum log --level warn "/dev/net/tun exists but cannot be opened (missing perms/caps/device policy?)"
  fi
else
  gum log --level warn "/dev/net/tun not present; TUN-based networking will be unavailable. Try running with --cap-add=MKNOD."
fi

# section 4 // nvidia gpu support

gum log --level debug "Generating LD cache..."
if [ -d /lib/x86_64-linux-gnu ] && [ "$(ls -A /lib/x86_64-linux-gnu/*.so* 2>/dev/null)" ]; then
  gum log --level debug "Found NVIDIA libraries, updating ld cache..."

  # Create symlinks for common library names
  for lib in /lib/x86_64-linux-gnu/*.so.*; do
    if [[ -f $lib ]]; then
      base=$(basename "$lib" | sed 's/\.so\..*//')
      ln -sf "$lib" "/lib/x86_64-linux-gnu/$base.so.1" 2>/dev/null || true
      ln -sf "$lib" "/lib/x86_64-linux-gnu/$base.so" 2>/dev/null || true
    fi
  done

  for cuda_path in /nix/store/*-cuda*/lib; do
    [ -d "$cuda_path" ] && echo "$cuda_path" >>/etc/ld.so.conf.d/nix-cuda.conf
  done

  ldconfig 2>/dev/null || true
  export LD_LIBRARY_PATH="/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib:${LD_LIBRARY_PATH:-}"
fi

# // nvidia-smi // validation and patching
gum log --level debug "Testing nvidia-smi..."
if [ -e /usr/bin/nvidia-smi ]; then
  if ! /usr/bin/nvidia-smi --version &>/dev/null; then
    gum log --level debug "Patching nvidia-smi..."

    INTERP=$(find /nix/store -name "ld-linux-x86-64.so.2" -type f | head -1)
    ([ -n "$INTERP" ] && patchelf --set-interpreter "$INTERP" /usr/bin/nvidia-smi 2>/dev/null) || true
    patchelf --set-rpath "/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib" /usr/bin/nvidia-smi 2>/dev/null || true
  fi

  if /usr/bin/nvidia-smi &>/dev/null; then
    gum log --level debug "GPU ready: $(/usr/bin/nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
  else
    gum log --level warn "nvidia-smi not functional"
    gum log --level debug "Library dependencies:"
    ldd /usr/bin/nvidia-smi 2>&1 | head -10 || true
    gum log --level debug "Available NVIDIA libraries:"
    printf '%s\n' /lib/x86_64-linux-gnu/libnvidia* 2>/dev/null | head -5
  fi
fi

# section 5 // authentication setup

if [ -n "${NIX2GPU_COPY_TO_ROOT:-}" ] && [ -d "$NIX2GPU_COPY_TO_ROOT/etc" ]; then
  gum log --level debug "Setting up /etc from nix store..."

  cp -r --reflink=auto --no-preserve=mode,ownership "$NIX2GPU_COPY_TO_ROOT/etc/"* /etc/ 2>/dev/null || true
fi

# // root // password
gum log --level debug "Configuring root authentication..."
if [ -n "${ROOT_PASSWORD:-}" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
else
  passwd -d root
fi

# section 6 // ssh setup

gum log --level debug "Configuring SSH..."

# Generate host keys if missing
for type in rsa ed25519; do
  key="/etc/ssh/ssh_host_${type}_key"
  [ ! -f "$key" ] && ssh-keygen -t "$type" -f "$key" -N "" >/dev/null 2>&1
done

# In bubblewrap mode, /etc/ssh may be a tmpfs overlay. If sshd_config doesn't exist yet,
# Configure sshd to use unprivileged port when in bubblewrap mode
if [ -f /etc/ssh/sshd_config ] && [ "${NIX2GPU_BUBBLEWRAP_MODE:-}" = "1" ]; then
  sed -i 's/^Port 22$/Port 2222/' /etc/ssh/sshd_config
fi

gum log --level debug "Adding SSH keys..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -n "${SSH_PUBLIC_KEYS:-}" ]; then
  echo "$SSH_PUBLIC_KEYS" >"$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi

# section 7 // xdg directories

gum log --level debug "Setting XDG dirs"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="/run/user/$UID"
export XDG_BIN_HOME="$HOME/.local/bin"

# section 8 // finalization

gum log --level debug "Running extra startup script..."
