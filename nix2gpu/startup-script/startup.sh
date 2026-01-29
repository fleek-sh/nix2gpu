# shellcheck shell=bash

set -euo pipefail

gum log --level debug "Container initialization starting..."

export HOME="/root"

# section 1 // filesystem setup (nix store → container paths)

# // etc // populate from nix store when in bubblewrap mode (no /etc/passwd)
gum log --level debug "Setting up /etc..."
if [ -d /etc ] && [ ! -f /etc/passwd ]; then
  for base_etc in /nix/store/*-base-system/etc; do
    if [ -d "$base_etc" ]; then
      cp -r --no-preserve=all "$base_etc"/* /etc/
      break
    fi
  done

  if [ -d /etc/ssl/certs ]; then
    rm -f /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt 2>/dev/null || true
    for cacert in /nix/store/*-nss-cacert-*/etc/ssl/certs/ca-bundle.crt; do
      if [ -f "$cacert" ]; then
        ln -sf "$cacert" /etc/ssl/certs/ca-bundle.crt
        ln -sf "$cacert" /etc/ssl/certs/ca-certificates.crt
        break
      fi
    done
  fi

  if [ -f /etc/ssh/sshd_config ]; then
    gum log --level debug "Configuring sshd for unprivileged mode (port 2222)..."
    sed -i 's/^Port 22$/Port 2222/' /etc/ssh/sshd_config
  fi
fi

# // root // populate from nix store if empty (bubblewrap sandbox mode)
gum log --level debug "Setting up /root..."
if [ -d /root ] && [ ! -d /root/.config ]; then
  for base_root in /nix/store/*-base-system/root; do
    if [ -d "$base_root" ]; then
      cp -r --no-preserve=all "$base_root"/* /root/ 2>/dev/null || true
      cp -r --no-preserve=ownership "$base_root"/.[!.]* /root/ 2>/dev/null || true
      break
    fi
  done
  chmod -R u+w /root 2>/dev/null || true
fi

# section 2 // runtime directories

gum log --level debug "Writing runtime directories"
mkdir -p /tmp /var/tmp /run /run/sshd /var/log /var/empty
chmod 1777 /tmp /var/tmp
chmod 755 /run/sshd

# section 3 // environment variables

gum log --level debug "Setting up environment"
export TMPDIR=/tmp
export NIX_BUILD_TOP=/tmp

# section 4 // network device setup

gum log --level debug "Enabling userspace networking"
mkdir -p /dev/net

if [ -c /dev/net/tun ]; then
  if ! (exec 3<>/dev/net/tun) 2>/dev/null; then
    gum log --level warn "/dev/net/tun exists but cannot be opened (missing perms/caps/device policy?)"
  fi
else
  gum log --level warn "/dev/net/tun not present; TUN-based networking will be unavailable. Try running with --cap-add=MKNOD."
fi

# section 5 // nvidia gpu support

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

# section 6 // authentication setup

# // dynamic // shadow file
gum log --level debug "Setting up shadow file..."
if [ ! -f /etc/shadow ]; then
  cp /nix/store/*/etc/shadow /etc/shadow
  chmod 0640 /etc/shadow
fi

# // root // password
gum log --level debug "Configuring root authentication..."
if [ -n "${ROOT_PASSWORD:-}" ]; then
  echo "root:$ROOT_PASSWORD" | chpasswd
else
  passwd -d root
fi

# section 7 // ssh setup

gum log --level debug "Adding SSH keys..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
if [ -n "${SSH_PUBLIC_KEYS:-}" ]; then
  echo "$SSH_PUBLIC_KEYS" >"$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
fi

# Generate host keys if missing
for type in rsa ed25519; do
  key="/etc/ssh/ssh_host_${type}_key"
  [ ! -f "$key" ] && ssh-keygen -t "$type" -f "$key" -N "" >/dev/null 2>&1
done

# section 8 // xdg directories

gum log --level debug "Setting XDG dirs"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_DATA_DIRS="/usr/local/share:/usr/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CONFIG_DIRS="/etc/xdg"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="/run/user/$UID"
export XDG_BIN_HOME="$HOME/.local/bin"

# section 9 // finalization

gum log --level debug "Running extra startup script..."
