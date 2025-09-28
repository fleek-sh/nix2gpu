{
  perSystem =
    { pkgs, ... }:
    {
      packages.networkPkgs = pkgs.symlinkJoin {
        name = "network-pkgs";
        paths = with pkgs; [
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
      };
    };
}
