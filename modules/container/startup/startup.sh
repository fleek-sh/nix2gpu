echo "[nix2vast] Container initialization starting..."

# // critical // runtime directories
mkdir -p /tmp /var/tmp /run /run/sshd /var/log /var/empty /var/lib/tailscale
chmod 1777 /tmp /var/tmp
chmod 755 /run/sshd
export TMPDIR=/tmp
export NIX_BUILD_TOP=/tmp

# // devices // userspace networking
mkdir -p /dev/net
[ ! -c /dev/net/tun ] && mknod /dev/net/tun c 10 200 && chmod 0666 /dev/net/tun

# // ldconfig // regenerate cache with NVIDIA libs
if [ -d /lib/x86_64-linux-gnu ] && [ "$(ls -A /lib/x86_64-linux-gnu/*.so* 2>/dev/null)" ]; then
  echo "[nix2vast] Found NVIDIA libraries, updating ld cache..."

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
  echo "[nix2vast] Setting root password..."
  echo "root:$ROOT_PASSWORD" | chpasswd
else
  echo "[nix2vast] Enabling passwordless root..."
  passwd -d root
fi

# // ssh // keys
mkdir -p /root/.ssh
chmod 700 /root/.ssh
if [ -n "${SSH_PUBLIC_KEYS:-}" ]; then
  echo "$SSH_PUBLIC_KEYS" >/root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
fi

# // nvidia-smi // validation
if [ -e /usr/bin/nvidia-smi ]; then
  echo "[nix2vast] Testing nvidia-smi..."

  # First check if it needs patching
  if ! /usr/bin/nvidia-smi --version &>/dev/null; then
    echo "[nix2vast] Patching nvidia-smi..."

    # Find the correct interpreter
    INTERP=$(find /nix/store -name "ld-linux-x86-64.so.2" -type f | head -1)
    ([ -n "$INTERP" ] && patchelf --set-interpreter "$INTERP" /usr/bin/nvidia-smi 2>/dev/null) || true

    # Set rpath to include the ACTUAL library locations
    patchelf --set-rpath "/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib" /usr/bin/nvidia-smi 2>/dev/null || true
  fi

  if /usr/bin/nvidia-smi &>/dev/null; then
    echo "[nix2vast] GPU ready: $(/usr/bin/nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)"
  else
    echo "[nix2vast] Warning: nvidia-smi not functional"
    # Debug info
    echo "[nix2vast] Library dependencies:"
    ldd /usr/bin/nvidia-smi 2>&1 | head -10 || true
    echo "[nix2vast] Available NVIDIA libraries:"
    printf '%s\n' /lib/x86_64-linux-gnu/libnvidia* 2>/dev/null | head -5
  fi
fi

for type in rsa ecdsa ed25519; do
  key="/etc/ssh/ssh_host_${type}_key"
  [ ! -f "$key" ] && ssh-keygen -t "$type" -f "$key" -N "" >/dev/null 2>&1
done

# // `tailscaled` // userspace
echo "[nix2vast] Starting Tailscale daemon..."
tailscaled --tun=userspace-networking --socket=/var/run/tailscale/tailscaled.sock 2>&1 &

if [ -n "${TAILSCALE_AUTHKEY:-}" ]; then
  echo "[nix2vast] authenticating tailscale..."
  sleep 3
  tailscale up --authkey="$TAILSCALE_AUTHKEY" --ssh &
else
  echo "[nix2vast] Tailscale running (no authkey provided)"
fi

echo "[nix2vast] activating home-manager..."
home-manager-generation

# // ssh // daemon
echo "[nix2vast] starting ssh daemon..."
$(which sshd) -t || exit 1
$(which sshd) -D -e &

# // config // extra startup script
echo "[nix2vast] running extra startup script..."
