{
  inputs,
  pkgs,
  system,
  lib,
  self,
  self',
  ...
}:
let
  nix2containerPkgs = inputs.nix2container.packages.${system};

  # Import components from lib
  inherit (import ../lib/users.nix { inherit lib pkgs; }) passwdContents shadowContents groupContents;

  inherit (import ../lib/config.nix { inherit pkgs self; }) nixConfContents sshdConfig startupScript;

  # Import packages
  inherit (import ./environment.nix { inherit pkgs lib; })
    cudaEnv
    corePkgs
    devPkgs
    networkPkgs
    ;

  inherit
    (import ./system.nix {
      inherit
        pkgs
        lib
        passwdContents
        shadowContents
        groupContents
        nixConfContents
        sshdConfig
        ;
    })
    baseSystem
    nixStoreProfile
    ;

  allPkgs =
    corePkgs
    ++ networkPkgs
    ++ devPkgs
    ++ [
      self'.packages.container-services
      cudaEnv
    ];

  profile = pkgs.buildEnv {
    name = "nix2vast-profile";
    paths = allPkgs;
    pathsToLink = [
      "/bin"
      "/sbin"
      "/lib"
      "/libexec"
      "/share"
    ];
  };
in
nix2containerPkgs.nix2container.buildImage {
  name = "nix2vast";
  tag = "latest";

  copyToRoot = [
    baseSystem
    nixStoreProfile
    profile
  ];

  initializeNixDatabase = true;

  config = {
    entrypoint = [
      "${pkgs.tini}/bin/tini"
      "--"
      "${startupScript}/bin/startup.sh"
    ];

    Env = [
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

    WorkingDir = "/root";
    User = "root";

    ExposedPorts = {
      "22/tcp" = { };
    };

    Labels = {
      "ai.vast.gpu" = "required";
      "ai.vast.runtime" = "nix2vast";
      "com.nvidia.volumes.needed" = "nvidia_driver";
      "com.nvidia.cuda.version" = "12.8";
      "org.opencontainers.image.source" = "https://github.com/fleek-platform/nix2vast";
      "org.opencontainers.image.description" = "Nix-based GPU container with Tailscale mesh";
    };
  };

  maxLayers = 50;
}
