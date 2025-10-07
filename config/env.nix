{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) pkgs;
in
{
  options.env = mkOption {
    description = ''
      environment variables to set inside your container.

      looking to install packages without effecting the
      default set? see `extraEnv`.
    '';
    type = types.listOf types.str;
    default = [
      "CUDA_VERSION=12.8"
      "CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt"
      "HOME=/root"
      "LANG=en_US.UTF-8"
      "LC_ALL=en_US.UTF-8"
      "LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib64:/usr/lib"
      "LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
      "NIXPKGS_ALLOW_UNFREE=1"
      "NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels"
      "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "NVIDIA_DISABLE_REQUIRE=0"
      "NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics"
      "NVIDIA_REQUIRE_CUDA=cuda>=11.0"
      "NVIDIA_VISIBLE_DEVICES=all"
      "PATH=/root/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
      "TERM=xterm-256color"
      "USER=root"
    ];
  };
}
