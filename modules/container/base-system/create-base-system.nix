{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options.createBaseSystem = mkOption {
          description = ''
            nix2vast script to generate baseSystem for ${container.name}.
          '';
          type = types.package;
          internal = true;
        };
      }
    );
  });

  config = {
    perSystem =
      { pkgs, config, ... }:
      {
        perContainer =
          { container, ... }:
          {
            createBaseSystem = pkgs.replaceVarsWith {
              src = ./create-system.sh;
              dir = "bin";
              isExecutable = true;
              replacements = {
                inherit (container.options) sshdConfig nixConfig;

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
      };
  };
}
