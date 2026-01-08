# shellcheck shell=bash
set -euo pipefail

if ! [ -v out ]; then
  printf '\033[31mError:\033[0m %s.\n' "'out' was not defined, please make sure you are running this in a nix build script"
  exit 1
fi

# // FHS // directories
mkdir -p \
  "$out"/{bin,sbin,lib,lib64,usr,var,run,tmp,home,root,proc,sys,dev,etc} \
  "$out"/usr/{bin,sbin,local} \
  "$out"/usr/local/{bin,sbin} \
  "$out"/var/{log,cache,lib,run,empty,tmp} \
  "$out"/run/lock \
  "$out"/dev/dri

write-passwd
write-group
write-shadow
write-nix
write-sshd
write-ld

# Nixpkgs config for unfree packages
mkdir -p "$out/root/.config/nixpkgs"
cat >"$out/root/.config/nixpkgs/config.nix" <<'EOF'
{
  allowUnfree = true;
  cudaSupport = true;
}
EOF

# // nvidia-container-toolkit // paths
mkdir -p \
  "$out/lib/x86_64-linux-gnu" \
  "$out/lib/firmware/nvidia/575.64.03" \
  "$out/usr/lib64" \
  "$out/usr/lib32" \
  "$out/usr/lib/x86_64-linux-gnu" \
  "$out/usr/local/lib" \
  "$out/usr/local/lib64"

# // ld.so // nvidia-container-cli
mkdir -p "$out/etc/ld.so.conf.d"
touch "$out/etc/ld.so.cache"

cat >"$out/etc/ld.so.conf" <<'EOF'
include /etc/ld.so.conf.d/*.conf
/lib/x86_64-linux-gnu
/usr/local/lib64
/usr/local/lib
/usr/lib64
/usr/lib/x86_64-linux-gnu
/usr/lib32
/usr/lib
/lib64
/lib
EOF

cat >"$out/etc/ld.so.conf.d/nvidia.conf" <<'EOF'
/lib/x86_64-linux-gnu
/usr/lib64
/usr/lib
EOF

# // ssl // certificates
mkdir -p "$out/etc/ssl/certs"
ln -s cacert/etc/ssl/certs/ca-bundle.crt "$out/etc/ssl/certs/ca-bundle.crt"
ln -s cacert/etc/ssl/certs/ca-bundle.crt "$out/etc/ssl/certs/ca-certificates.crt"

cat >"$out/etc/nsswitch.conf" <<'EOF'
passwd:    files
group:     files
shadow:    files
hosts:     files dns
networks:  files
EOF

cat >"$out/etc/hosts" <<'EOF'
127.0.0.1   localhost
::1         localhost
EOF

cat >"$out/etc/os-release" <<'EOF'
NAME="nix2gpu"
ID=nix2gpu
VERSION="1.0"
PRETTY_NAME="nix2gpu GPU container"
EOF

# // shell // compatibility
bash_path="$(which bash)"
ln -s "$bash_path" "$out/bin/bash"
ln -s "$bash_path" "$out/bin/sh"
ln -s "$(which env)" "$out/usr/bin/env"

# // nvidia-container-cli // ldconfig
ldconfig_path="$(which ldconfig)"
ln -s "$ldconfig_path" "$out/sbin/ldconfig"
ln -s "$ldconfig_path" "$out/sbin/ldconfig.real"

# // locale
cat >"$out/etc/locale.conf" <<'EOF'
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF
