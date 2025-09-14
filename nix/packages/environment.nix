{ pkgs, lib }:
{
  cudaEnv = pkgs.symlinkJoin {
    name = "cuda-env";
    paths = with pkgs; [
      cudaPackages_12_8.cudatoolkit
      cudaPackages_12_8.cudnn
      cudaPackages_12_8.cusparselt
      cudaPackages_12_8.libcublas
      cudaPackages_12_8.libcufile
      cudaPackages_12_8.libcusparse
      cudaPackages_12_8.nccl
      nvtopPackages.nvidia
    ];

    postBuild = ''
      rm -f $out/LICENSE
      rm -f $out/version.txt
    '';
  };

  corePkgs = with pkgs; [
    bashInteractive
    bzip2
    cacert
    coreutils-full
    findutils
    gawk
    git
    gnugrep
    gnused
    gnutar
    gzip
    less
    man
    nano
    nix
    openssl
    p7zip
    pciutils
    procps
    shadow
    sudo
    tini
    unzip
    util-linux
    vim
    which
    xz
  ];

  devPkgs = with pkgs; [
    binutils
    elfutils
    file
    gcc
    glibc.bin
    gnumake
    patchelf
    pkg-config
    python312
    uv
  ];

  networkPkgs = with pkgs; [
    curl
    hostname
    inetutils
    iproute2
    iputils
    netcat-gnu
    openssh
    rclone
    tailscale
    wget
  ];

  shellPkgs = with pkgs; [
    atuin
    bat
    btop
    direnv
    eza
    fd
    file
    fzf
    htop
    jq
    lsof
    ltrace
    nix-direnv
    ripgrep
    starship
    strace
    tmux
    tree
    yq
    zoxide
  ];
}
