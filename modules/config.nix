{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
  inherit (flake-parts-lib) mkPerSystemOption;

  rootConfig = config;
in
{
  options.perSystem = mkPerSystemOption (
    { pkgs, config, ... }:
    {
      options.nix2vast = mkOption {
        description = ''
          Top level nix2vast config.

          TODO: put description here with examples.
        '';
        type = types.attrsOf (
          types.submodule (
            { name, ... }:
            {
              imports = [ (inputs.import-tree ../config) ];

              options = {
                name = mkOption {
                  type = types.str;
                  internal = true;
                  default = name;
                };
                rootConfig = mkOption {
                  internal = true;
                  default = rootConfig;
                };
                systemConfig = mkOption {
                  internal = true;
                  default = config;
                };
                pkgs = mkOption {
                  internal = true;
                  default = pkgs;
                };
              };
            }
          )
        );
      };
    }
  );
}
