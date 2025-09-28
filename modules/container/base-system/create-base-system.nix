{ config, ... }:
{
  flake.modules.createBaseSystem =
    { pkgs, system, ... }:
    pkgs.replaceVarsWith {
      src = ./create-system.sh;
      dir = "bin";
      isExecutable = true;
      replacements = {
        inherit (config.${system}.packages)
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
          ;

        glibcBin = pkgs.glibc.bin;
      };
    };
}
