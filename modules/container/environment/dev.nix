{
  flake.modules.devPkgs =
    { pkgs, ... }:
    with pkgs;
    [
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
}
