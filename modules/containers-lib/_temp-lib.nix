{
  lib,
  config,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  # TODO: pass to file without recursion errors
  mkTransposedPerContainerModule =
    {
      name,
      option,
      file,
    }:
    {
      _file = file;

      options = {
        container = flake-parts-lib.mkSubmoduleOptions {
          ${name} = mkOption {
            type = types.attrsWith {
              elemType = option.type;
              lazy = true;
              placeholder = "container";
            };
            default = { };
            description = ''
              See {option}`perContainer.${name}` for description and examples.
            '';
          };
        };

        perSystem = flake-parts-lib.mkPerSystemOption {
          perContainer = config.flake.lib.mkPerContainerOption {
            _file = file;

            options.${name} = option;
          };
        };
      };

      config = {
        perSystem = _: { containerTransposition.${name} = { }; };
        transposition.${name} = { };
      };
    };
}
