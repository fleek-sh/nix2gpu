{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types;
in
{
  options.createBaseSystem = flake-parts-lib.mkPerSystemOption {
    description = ''
      nix2vast script to generate baseSystem.
    '';
    type = types.package;
    internal = true;
  };

  config.createBaseSystem =
    { pkgs, config, ... }:
    pkgs.replaceVarsWith {
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
}
