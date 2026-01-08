{ pkgs, ... }:
{
  systemPackages = with pkgs; [
    curl
    hostname
    inetutils
    iproute2
    iputils
    netcat-gnu
    openssh
    rclone
    wget
  ];
}
