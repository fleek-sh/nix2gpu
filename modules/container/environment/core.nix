{
  perSystem =
    { pkgs, ... }:
    {
      perContainer = _: {
        environment.corePkgs = pkgs.symlinkJoin {
          name = "core-pkgs";
          paths = with pkgs; [
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
        };
      };
    };
}
