_:
{
  flake.packages.createBaseSystem =
    { pkgs, self', ... }:
    pkgs.replaceVarsWith {
      src = ./create-system.sh;
      dir = "bin";
      isExecutable = true;
      replacements = {
        inherit (self'.packages)
          passwdConf
          groupConf
          shadowConf
          nixConf
          sshdConf
          ;

        inherit (pkgs)
          bashInteractive
          coreutils-full
          glibc
          cacert
          ;

        glibcBin = pkgs.glibc.bin;
      };
    };
}
