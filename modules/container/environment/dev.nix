{
  perSystem =
    { pkgs, ... }:
    {
      perContainer = _: {
        environment.devPkgs = pkgs.symlinkJoin {
          name = "dev-pkgs";
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
      };
    };
}
