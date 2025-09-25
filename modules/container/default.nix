{ lib, config, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.nix2vast.perSystem =
    { pkgs, system, ... }:
    {
      name = mkOption {
        description = ''
          the name of your container
        '';
        type = types.str;
        default = "nix2vast";
      };

      tag = mkOption {
        description = ''
          the tag to use for your container
        '';
        type = types.str;
        default = "latest";
      };

      copyToRoot = mkOption {
        description = ''
          packages to copy to the root of your container.

          looking to install packages without effecting the
          default set? see `extraCopyToRoot`.
        '';
        type = types.listOf types.package;
        default = [
          config.${system}.packages.baseSystem
          config.${system}.packages.nixStoreProfile
          config.${system}.packages.profile
        ];
      };

      extraCopyToRoot = mkOption {
        description = ''
          extra packages to copy to the root of your container.
        '';
        type = types.listOf types.package;
        default = [ ];
      };

      env = mkOption {
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
          "RUN_SERVICES=1"
        ];
      };

      extraEnv = mkOption {
        description = ''
          extra environment variables to set inside your container.
        '';
        type = types.listOf types.str;
        default = [ ];
      };

      workingDir = mkOption {
        description = ''
          the working directory for your container to start in.
        '';
        type = types.str;
        default = "/root";
      };

      user = mkOption {
        description = ''
          the default user for your container.
        '';
        type = types.str;
        default = "root";
      };

      exposedPorts = mkOption {
        description = ''
          exposed ports for your container.
        '';
        type = types.attrsOf types.anything;
        default = {
          "22/tcp" = { };
        };
      };

      labels = mkOption {
        description = ''
          container labels to set.

          looking to add labels without effecting the
          default set? see `extraLabels`.
        '';
        type = types.attrsOf types.str;
        default = {
          "ai.vast.gpu" = "required";
          "ai.vast.runtime" = "nix2vast";
          "com.nvidia.volumes.needed" = "nvidia_driver";
          "com.nvidia.cuda.version" = config.cudaPackages.cudatoolkit.version;
          "org.opencontainers.image.source" = "https://github.com/fleek-platform/nix2vast";
          "org.opencontainers.image.description" = "Nix-based GPU container with Tailscale mesh";
        };
      };

      extraLabels = mkOption {
        description = ''
          extra container labels to set.
        '';
        type = types.attrsOf types.str;
        default = { };
      };

      maxLayers = mkOption {
        description = ''
          the maximum amount of layers to use when creating your container.
        '';
        type = types.int;
        default = 50;
      };
    };

  config.perSystem =
    { pkgs, system, ... }:
    let
      nix2vast = config.nix2vast.${system};
    in
    {
      packages.container = config.nix2containerPkgs.nix2container.buildImage {
        inherit (nix2vast) name tag maxLayers;

        copyToRoot = nix2vast.copyToRoot ++ nix2vast.extraCopyToRoot;
        initializeNixDatabase = true;

        config = {
          entrypoint = [
            "${pkgs.tini}/bin/tini"
            "--"
            "${config.${system}.packages.startupScript}/bin/startup.sh"
          ];

          Env = nix2vast.env ++ nix2vast.extraEnv;

          WorkingDir = nix2vast.workingDir;
          User = nix2vast.user;

          ExposedPorts = nix2vast.exposedPorts;

          Labels = nix2vast.labels ++ nix2vast.extraLabels;
        };
      };
    };
}
