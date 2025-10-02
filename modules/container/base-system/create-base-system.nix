{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
in
{

  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.createBaseSystem = mkOption {
      description = ''
        nix2vast script to generate baseSystem.
      '';
      type = types.package;
      internal = true;
    };
  });

  config.perSystem =
    { pkgs, config, ... }:
    {
      createBaseSystem = pkgs.replaceVarsWith {
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
