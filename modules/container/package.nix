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
        options.packages = mkOption {
          description = ''
            nix2vast packages for ${container.name}.
          '';
          type = types.lazyAttrsOf types.raw;
          internal = true;
        };
      }
    );
  });

  config = {
    perSystem =
      {
        config,
        pkgs,
        inputs',
        ...
      }:
      {
        packages = builtins.mapAttrs (name: value: value.packages.${name}) config.allContainers;

        perContainer =
          { container, config, ... }:
          let
            inherit (container) name options;

            toEnvStrings =
              envAttrs:
              lib.mapAttrsToList (
                name: val:

                assert lib.assertMsg (lib.toUpper name == name) ''
                  `nix2vast` env var names should be uppercase 
                  in order to be properly recognized.

                  The failing attribute name is `${name}`.
                '';

                "${name}-${val}"
              ) envAttrs;
          in
          {
            packages."${name}" = inputs'.nix2container.packages.nix2container.buildImage {
              inherit name;
              inherit (options) tag maxLayers;

              copyToRoot = options.copyToRoot ++ options.extraCopyToRoot;
              initializeNixDatabase = true;

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

              passthru = {
                inherit (config.scripts)
                  copyToGithub
                  loginToGithub
                  podmanShell
                  dockerShell
                  shell
                  ;
              };
            };
          };
      };
  };
}
