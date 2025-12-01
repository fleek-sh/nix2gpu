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
          A function that applies configurations to each container defined in `nix2gpu`.

          Think of `perContainer` as a cookie cutter for your containers. You define the
          shape of the cookie once (the configuration), and `nix2gpu` uses it to cut
          out a cookie for each container you've defined in `nix2gpu.<container-name>`.

          This allows you to write container configurations once and apply them across
          all your containers, making your flake more DRY (Don't Repeat Yourself).

          How it works:

          For each container you define under the `nix2gpu` option in your `flake.nix`,
          `nix2gpu` will call the `perContainer` function. This function is passed
          a set of arguments, including a `container` attribute, which holds the
          specifics of the container being processed.

          The `container` attribute contains:
          - `name`: The name of the container (e.g., `"my-container"`).
          - `options`: The options you've defined for that container under `nix2gpu.<container-name>`.

          Analogy to `perSystem`:

          As the name suggests, `perContainer` is analogous to `flake-parts`' `perSystem`.
          While `perSystem` applies configurations to each system (like `x86_64-linux`),
          `perContainer` applies configurations to each container defined in `nix2gpu`.
          This provides a powerful and consistent way to manage configurations at
          different levels of your flake.
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
        example = ''
          { flake-parts-lib, lib, inputs, ...}:
          let
            inherit (lib) types mkOption;
            inherit (flake-parts-lib) mkPerSystemOption;
            inherit (inputs.nix2gpu.lib) mkPerContainerOption;
          in
          {
            options.perSystem = mkPerSystemOption {
              options.perContainer = mkPerContainerOption (
                { container, ... }:
                {
                  options.myOption = mkOption {
                    description = '''
                      unique option that exists for ''${container.name}
                    ''';
                    type = types.str;
                  };
                }
              );
            });

            config.perSystem = { pkgs, ... }: {
              nix2gpu = {
                # Define two containers
                my-app = {
                  # container-specific options
                  workingDir = "/app";
                };
                my-db = {
                  # container-specific options
                  workingDir = "/data";
                };
              };

              # Use perContainer to apply common settings
              perContainer = { container, ... }: {
                myOption = "hello world, ''${container.name}!";
              };
            };
          }
        '';
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
              A nix2gpu` attribute name has failed a restriction by container parsing rules - https://pkg.go.dev/github.com/distribution/reference#pkg-variables

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
      ) config.nix2gpu;

      containerPer = builtins.map config.perContainer containersList;

      containerNames = lib.attrNames config.nix2gpu;
    in
    {
      allContainers = lib.attrsets.mergeAttrsList (
        lib.zipListsWith (name: modules: { "${name}" = modules; }) containerNames containerPer
      );

    };

  config.flake.lib = { inherit mkPerContainerOption mkPerContainerType; };
}
