{
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (lib) mapAttrs mkOption types;

  transpositionModule.options.adHoc = mkOption {
    type = types.bool;
    default = false;
    description = ''
      Whether to provide a stub option declaration for {option}`perContainer.<name>`.

      The stub option declaration does not support merging and lacks
      documentation, so you are recommended to declare the {option}`perContainer.<name>`
      option yourself and avoid {option}`adHoc`.
    '';
  };

in
{
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption (_: {
      options = {
        containerTransposition = lib.mkOption {
          description = ''
            A helper that defines transposed attributes in the flake outputs.

            When you define `containerTransposition.foo = { };`, definitions are added to the effect of (pseudo-code):

            ```nix
            flake.foo.''${container} = (perContainer container).foo;
            ```

            Transposition is the operation that swaps the indices of a data structure.
            Here it refers specifically to the transposition between

            ```plain
            perContainer: .''${container}.''${attribute}
            outputs:   .''${attribute}.''${container}
            ```
          '';
          type = types.lazyAttrsOf (types.submoduleWith { modules = [ transpositionModule ]; });
        };

        flake = mkOption {
          type = types.submoduleWith {
            modules = [
              {
                freeformType = types.lazyAttrsOf (
                  types.unique {
                    message = ''
                      No option has been declared for this flake output attribute, so its definitions can't be merged automatically.
                      Possible solutions:
                        - Load a module that defines this flake output attribute
                          Many modules are listed at https://flake.parts
                        - Declare an option for this flake output attribute
                        - Make sure the output attribute is spelled correctly
                        - Define the value only once, with a single definition in a single module
                    '';
                  } types.raw
                );
              }
            ];
          };
          description = ''
            Raw flake output attributes. Any attribute can be set here, but some
            attributes are represented by options, to provide appropriate
            configuration merging.
          '';
        };

      };
    });
  };

  config = {
    perSystem =
      { config, ... }:
      {
        flake = lib.mapAttrs (
          attrName: _attrConfig:
          mapAttrs (
            _system: v:
            v.${attrName} or (abort ''
              Could not find option ${attrName} in the perContainer module. It is required to declare such an option whenever containerTansposition.<name> is defined (and in this instance <name> is ${attrName}).
            '')
          ) config.allContainers
        ) config.containerTransposition;
      };
  };
}
