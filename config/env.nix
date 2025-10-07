{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) pkgs;
in
# TODO: make this and `extraEnv` actual nix attributes instead of "X=Y" strings
{
  options.env = mkOption {
    description = ''
      A list of environment variables to set inside the container.

      This option allows you to define the environment variables that will be
      available within the container.

      The default value provides a comprehensive set of environment variables
      for a typical development environment, including paths for Nix, CUDA,
      and other essential tools.

      If you want to add extra environment variables without replacing the
      default set, use the `extraEnv` option instead.

      Each variable should be a string in the format `"KEY=VALUE"`.

      > This is a direct mapping to the `Env` attribute of the [oci container
      > spec](https://github.com/opencontainers/image-spec/blob/8b9d41f48198a7d6d0a5c1a12dc2d1f7f47fc97f/specs-go/v1/config.go#L23). 

      **Example:**

      ```nix
      env = [
        "MY_CUSTOM_VARIABLE=hello"
        "ANOTHER_VARIABLE=world"
      ];
      ```
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
