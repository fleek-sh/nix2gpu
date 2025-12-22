{ rootInputs, ... }:
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
  options.perSystem = flake-parts-lib.mkPerSystemOption {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options = {
          packages = mkOption {
            description = ''
              nix2gpu packages for ${container.name}.
            '';
            type = types.lazyAttrsOf types.raw;
            internal = true;
          };
          checks = mkOption {
            description = ''
              `nix flake check` bindings for ${container.name}
            '';
            type = types.lazyAttrsOf types.raw;
            internal = true;
          };
        };
      }
    );
  };

  config.perSystem =
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      inherit (rootInputs.nix2container.packages.${system}.nix2container) buildImage;

      mkContainerChecks =
        containerName: containerCfg:
        lib.mapAttrs' (name: value: lib.nameValuePair "${containerName}-${name}" value) containerCfg.checks;
    in
    {
      packages = builtins.mapAttrs (name: value: value.packages.${name}) config.allContainers;
      checks = lib.pipe config.allContainers [
        (builtins.mapAttrs mkContainerChecks)
        builtins.attrValues
        lib.mergeAttrsList
      ];

      perContainer =
        { container, config, ... }:
        let
          inherit (container) name options;

          toEnvStrings =
            envAttrs:
            lib.mapAttrsToList (
              name: val:

              assert lib.assertMsg (lib.toUpper name == name) ''
                `nix2gpu` env var names should be uppercase 
                in order to be properly recognized.

                The failing attribute name is `${name}`.
              '';

              "${name}=${val}"
            ) envAttrs;
        in

        assert lib.assertMsg (options.tag != "") ''
          The `tag` option for container `${name}` must be a non-empty string.
        '';

        rec {
          packages."${name}" =
            (buildImage {
              inherit name;
              inherit (options) tag;

              inherit (options) maxLayers;
              initializeNixDatabase = true;

              copyToRoot = options.copyToRoot ++ options.extraCopyToRoot;

              config = {
                entrypoint = [
                  "${pkgs.tini}/bin/tini"
                  "--"
                  "${config.startupScript}/bin/${container.name}-startup.sh"
                ];

                Env = (toEnvStrings options.env) ++ (toEnvStrings options.extraEnv);

                WorkingDir = options.workingDir;
                User = options.user;

                ExposedPorts = options.exposedPorts;

                Labels = options.labels // options.extraLabels;
              };
            }).overrideAttrs
              (oldAttrs: {
                passthru = (oldAttrs.passthru or { }) // config.scripts;
              });

          checks."is-valid" = packages.${name};
        };
    };
}
