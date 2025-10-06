{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
  inherit (flake-parts-lib) mkPerSystemOption;

  rootConfig = config;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { pkgs, config, ... }:
    {
      options.nix2vast = mkOption {
        description = ''
          Top level nix2vast config.

          TODO: put description here with examples.
        '';
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              options = {
                tag = mkOption {
                  description = ''
                    the tag to use for your container
                  '';
                  type = types.str;
                  default = "latest";
                };

                services = mkOption {
                  description = ''
                    the [`services-flake`](https://github.com/juspay/services-flake)
                    configuration to use inside your `nix2vast` container.

                    when your container is launched it boots into a
                    [process-compose](https://github.com/F1bonacc1/process-compose]
                    interface running all services specificed. 

                    this can be useful for running your own web servers or things
                    like nginx.
                  '';
                  type = types.lazyAttrsOf types.raw;
                  default = { };
                };

                home = mkOption {
                  description = ''
                    the [`home-manager`](https://github.com/nix-community/home-manager)
                    configuration to use inside your `nix2vast` container.

                    by default a minimal set of useful modern shell packages and
                    agenix integration is included for hacking on your machines.
                  '';
                  type = types.lazyAttrsOf types.raw;
                  inherit (config.homeConfigurations) default;
                };

                extraStartupScript = mkOption {
                  description = ''
                    extra commands to run on container startup.
                  '';
                  type = types.str;
                  default = "";
                };

                nixConfig = mkOption {
                  description = ''
                    a replacement nix.conf to use.
                  '';
                  type = types.str;
                  default = builtins.readFile ./container/config/nix.conf;
                };

                sshdConfig =
                  let
                    sshdConf = pkgs.replaceVars ./container/config/sshd_config { inherit (pkgs) openssh; };
                  in
                  mkOption {
                    description = ''
                      a replacement sshd configuration to use.
                    '';
                    type = types.str;
                    default = builtins.readFile sshdConf;
                  };

                registry = mkOption {
                  description = ''
                    the container registry to push your images to.
                  '';
                  type = types.str;
                  default = "";
                };

                cudaPackages = mkOption {
                  description = ''
                    the cuda packages source to use.

                    this is useful for selecting a specific version
                    on which your container relies.
                  '';
                  type = rootConfig.types.cudaPackageSet;
                  default = pkgs.cudaPackages_12_8;
                };

                copyToRoot = mkOption {
                  description = ''
                    packages to copy to the root of your container.

                    looking to install packages without effecting the
                    default set? see `extraCopyToRoot`.
                  '';
                  type = types.listOf types.package;
                  default = with config; [
                    allContainers.${name}.baseSystem
                    allContainers.${name}.profile
                    nixStoreProfile
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
                    "com.nvidia.cuda.version" = config.nix2vast.${name}.cudaPackages.cudatoolkit.version;
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
            }
          )
        );
      };
    }
  );
}
