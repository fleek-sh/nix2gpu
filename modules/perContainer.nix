{
  lib,
  config,
  flake-parts-lib,
  ...
}:
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

        top@{ config, lib, , ... }: {
          perSystem = { ${param}, ... }: {
            # in scope here:
            #  - ${param}
            #  - config (of perSystem)
            #  - top.config (note the `top@` pattern)
          };
        }
    '';

  # Lifted from flake-parts
  # Differs from nixpkgs implementation slightly
  deferredModuleWith =
    attrs@{
      staticModules ? [ ],
    }:
    lib.mkOptionType {
      name = "deferredModule";
      description = "module";
      check = x: lib.isAttrs x || lib.isFunction x || lib.types.path.check x;
      merge =
        loc: defs:
        staticModules
        ++ map (
          def: lib.setDefaultModuleLocation "${def.file}, via option ${lib.showOption loc}" def.value
        ) defs;
      inherit (lib.types.submoduleWith { modules = staticModules; }) getSubOptions getSubModules;
      substSubModules = m: deferredModuleWith (attrs // { staticModules = m; });
      functor = lib.defaultFunctor "deferredModuleWith" // {
        type = deferredModuleWith;
        payload = { inherit staticModules; };
        binOp = lhs: rhs: { staticModules = lhs.staticModules ++ rhs.staticModules; };
      };
    };

  mkPerContainerType = module: deferredModuleWith { staticModules = [ module ]; };
  mkPerContainerOption = module: lib.mkOption { type = mkPerContainerType module; };
in
{
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

          _module.args.config = throwShouldBePerSystemError "config";
          _module.args.getSystem = throwShouldBePerSystemError "getSystem";
          _module.args.withSystem = throwShouldBePerSystemError "withSystem";
          _module.args.moduleWithSystem = throwShouldBePerSystemError "moduleWithSystem";
        };
      });
      apply =
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
    };

    allContainers = mkOption {
      type = types.lazyAttrsOf types.unspecified;
      description = "The container-specific config for each of systems.";
      internal = true;
    };
  };

  config =
    let
      containersList = lib.mapAttrsToList (name: options: { inherit name options; }) config.nix2vast;

      containerPer = builtins.map config.perContainer containersList;

      containerNames = lib.attrNames config.nix2vast;
    in
    {
      allContainers = lib.attrsets.mergeAttrsList
        (lib.zipListsWith
          (name: modules: { "${name}" = modules; })
          containerNames
          containerPer);

      flake.lib = { inherit mkPerContainerOption mkPerContainerType; };
    };
}
