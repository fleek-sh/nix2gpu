{
  flake.modules.networkPkgs.perSystem =
    { pkgs, ... }:
    with pkgs;
    [
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
}
