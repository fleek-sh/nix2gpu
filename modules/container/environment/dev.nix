{
  flake.packages.devPkgs =
    { pkgs, ... }:

    pkgs.symlinkJoin {
      name = "network-pkgs";
      paths = with pkgs; [
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
    };
}
