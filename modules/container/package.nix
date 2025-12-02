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
        options.packages = mkOption {
          description = ''
            nix2gpu packages for ${container.name}.
          '';
          type = types.lazyAttrsOf types.raw;
          internal = true;
        };
      }
    );
  };

  config.perSystem =
    {
      config,
      pkgs,
      inputs',
      ...
    }:
    let
      buildImage =
        if (inputs' ? nix2container) then
          inputs'.nix2container.packages.nix2container.buildImage
        else
          pkgs.dockerTools.buildImage;
    in
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

        {
          packages."${name}" =
            (buildImage (
              (lib.optionalAttrs (inputs' ? nix2container) {
                inherit (options) maxLayers;
                initializeNixDatabase = true;
              })
              // {
                inherit name;
                inherit (options) tag;

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
              }
            )).overrideAttrs
              (oldAttrs: {
                passthru = (oldAttrs.passthru or { }) // config.scripts;
              });
        };
    };
}
