{ lib, flake-parts-lib, ... }:
let
  inherit (lib) mkOption types;

  throwShouldBeTopError =
    param:
    throw ''
      `${param}` is not a `perContainer` module argument, but a module argument of
      the top level config.

      The following is an example usage of `${param}`. Note that its binding
      is in the `top` parameter list, which is declared by the top level module
      rather than the `perContainer` module.

        top@{ config, lib, ${param}, ... }: {
          perContainer = { container, ... }: {
            # in scope here:
            #  - ${param}
            #  - container (of perContainer)
            #  - top.config (note the `top@` pattern)
          };
        }
    '';

  throwShouldBePerSystemError =
    param:
    throw ''
      `${param}` is not a `perContainer` module argument, but a module argument of
      `perSystem`.

      The following is an example usage of `${param}`. Note that its binding
      is in the `perSystem` parameter list, rather than the `perContainer` module.

        top@{ config, lib, ... }: {
          perSystem = { ${param}, ... }: {
            # in scope here:
            #  - ${param}
            #  - config (of perSystem)
            #  - top.config (note the `top@` pattern)
          };
        }
    '';

  mkPerContainerType = flake-parts-lib.mkDeferredModuleType;
  mkPerContainerOption = flake-parts-lib.mkDeferredModuleOption;

  evaluteModulesPerContainer =
    modules: container:
    (lib.evalModules {
      inherit modules;
      prefix = [
        "perContainer"
        container.name
      ];
      specialArgs = { inherit container flake-parts-lib; };
      class = "perContainer";
    }).config;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options = {
      perContainer = mkOption {
        description = ''
          A function from container to flake-like attributes omitting the `<container>` attribute.

          Modules defined here have access to a `container` struct holding the `name` and
          `options` fields for every container.

          Behaves similarly to `perSystem` from `flake-parts`.
        '';
        type = mkPerContainerType (_: {
          _file = ./perContainer.nix;
          config = {
            _module.args.self = throwShouldBeTopError "self";
            _module.args.inputs = throwShouldBeTopError "inputs";

            _module.args.getSystem = throwShouldBePerSystemError "getSystem";
            _module.args.withSystem = throwShouldBePerSystemError "withSystem";
            _module.args.moduleWithSystem = throwShouldBePerSystemError "moduleWithSystem";
          };
        });
        apply = evaluteModulesPerContainer;
      };

      allContainers = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        description = "The container-specific config for each of systems.";
        internal = true;
      };
    };
  });

  config.perSystem =
    { config, ... }:
    let
      containersList = lib.mapAttrsToList (
        name: options:
        let
          mkContainerAssert =
            assertation: message:
            lib.assertMsg assertation ''
              A nix2vast` attribute name has failed a restriction by container parsing rules - https://pkg.go.dev/github.com/distribution/reference#pkg-variables

              `${name}` ${message}.
            '';
        in

        assert mkContainerAssert (lib.toLower name == name) "should be lowercase";
        assert mkContainerAssert (
          lib.stringLength name < 255
        ) "should be less than 255 characters in length";
        assert mkContainerAssert (lib.stringLength name > 1) "should be more than 1 character in length";
        assert mkContainerAssert (builtins.match "[a-z0-9][a-z0-9_.-]*[a-z0-9]" name == [ ])
          "should start with and end with a number or letter, while containing any amount of `.`, `-`, `_`, a letter or a number";

        {
          inherit name options;
        }
      ) config.nix2vast;

      containerPer = builtins.map config.perContainer containersList;

      containerNames = lib.attrNames config.nix2vast;
    in
    {
      allContainers = lib.attrsets.mergeAttrsList (
        lib.zipListsWith (name: modules: { "${name}" = modules; }) containerNames containerPer
      );

    };

  config.flake.lib = { inherit mkPerContainerOption mkPerContainerType; };
}
