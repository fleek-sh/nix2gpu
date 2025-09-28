mkdir -p $out/etc

cp @passwdContents@ $out/etc/passwd
cp @groupContents@ $out/etc/group
cp @shadowContents@ $out/etc/shadow

mkdir -p $out/etc/nix
cp @nixConfig@ $out/etc/nix/nix.conf

# Nixpkgs config for unfree packages
mkdir -p $out/root/.config/nixpkgs
cat >$out/root/.config/nixpkgs/config.nix <<'EOF'
{
  allowUnfree = true;
  cudaSupport = true;
}
EOF

mkdir -p $out/etc/ssh
cp @sshdConfig@ $out/etc/ssh/sshd_config

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
mkdir -p $out/etc/ld.so.conf.d
touch $out/etc/ld.so.cache

cat >$out/etc/ld.so.conf <<'EOF'
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

cat >$out/etc/ld.so.conf.d/nvidia.conf <<'EOF'
/lib/x86_64-linux-gnu
/usr/lib64
/usr/lib
EOF

# // ssl // certificates
mkdir -p $out/etc/ssl/certs
ln -s @cacert@/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-bundle.crt
ln -s @cacert@/etc/ssl/certs/ca-bundle.crt $out/etc/ssl/certs/ca-certificates.crt

cat >$out/etc/nsswitch.conf <<'EOF'
passwd:    files
group:     files
shadow:    files
hosts:     files dns
networks:  files
EOF

cat >$out/etc/hosts <<'EOF'
127.0.0.1   localhost
::1         localhost
EOF

cat >$out/etc/os-release <<'EOF'
NAME="nix2vast"
ID=nix2vast
VERSION="1.0"
PRETTY_NAME="nix2vast GPU container"
EOF

# // FHS // directories
mkdir -p \
  "$out/{bin,sbin,lib,lib64,usr,var,run,tmp,home,root,proc,sys,dev}" \
  "$out/usr/{bin,sbin,local}" \
  "$out/usr/local/{bin,sbin}" \
  "$out/var/{log,cache,lib,run,empty,tmp}" \
  "$out/run/lock" \
  "$out/dev/dri"

# // shell // compatibility
ln -s @bashInteractive@/bin/bash $out/bin/bash
ln -s @bashInteractive@/bin/bash $out/bin/sh
ln -s @coreutils-full@/bin/env $out/usr/bin/env

# // nvidia-container-cli // ldconfig
mkdir -p $out/sbin
ln -s @glibcBin@/sbin/ldconfig $out/sbin/ldconfig
ln -s @glibcBin@/sbin/ldconfig.real $out/sbin/ldconfig.real

# // dynamic linking // standard interpreter
mkdir -p $out/lib64
if [ -e @glibc@/lib/ld-linux-x86-64.so.2 ]; then
  ln -s @glibc@/lib/ld-linux-x86-64.so.2 $out/lib64/ld-linux-x86-64.so.2
fi

# // locale
cat >$out/etc/locale.conf <<'EOF'
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF
