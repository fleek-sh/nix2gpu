{
  perSystem =
    { pkgs, config, ... }:
    {
      packages.createBaseSystem = pkgs.replaceVarsWith {
        src = ./create-system.sh;
        dir = "bin";
        isExecutable = true;
        replacements = {
          inherit (config.nix2vast) sshdConfig nixConfig;

          inherit (config) passwdContents groupContents shadowContents;

          inherit (pkgs)
            bashInteractive
            coreutils-full
            glibc
            cacert
            ;

          glibcBin = pkgs.glibc.bin;
        };
      };
    };
}
