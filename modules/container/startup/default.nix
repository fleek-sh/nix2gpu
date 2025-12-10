{
  config,
  lib,
  flake-parts-lib,
  inputs,
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
        options.startupScript = mkOption {
          description = ''
            nix2gpu container ${container.name} startup script.
          '';
          type = types.package;
          internal = true;
        };
      }
    );
  };

  config.perSystem =
    {
      pkgs,
      config,
      self',
      ...
    }:
    let
      outerConfig = config;
    in
    {
      perContainer =
        { container, config, ... }:
        let
          hasServices = inputs ? services-flake && inputs ? process-compose-flake && container ? services;
        in
        {
          startupScript =
            let
              scriptText = ''
                ${builtins.readFile ./startup.sh}

                ${lib.optionalString (inputs ? home-manager) ''
                  echo "[nix2gpu] activating home-manager..."
                  home-manager-generation
                ''}

                ${outerConfig.nix2gpu.${container.name}.extraStartupScript}

                ${if hasServices then ''
                  if [[ $- != *i* ]] || ! [ -t 0 ]; then
                    export PC_DISABLE_TUI=true
                  fi

                  echo "[nix2gpu] starting services..."
                  ${container.name}-services
                '' else ''
                  echo "[nix2gpu] entering interactive terminal..."
                  sleep infinity
                ''}
              '';
            in
            pkgs.writeShellApplication {
              name = "${container.name}-startup.sh";
              text = scriptText;

              runtimeInputs =
                with config;
                [
                  environment.corePkgs
                  environment.networkPkgs
                ]
                ++ lib.optionals hasServices [ self'.packages."${container.name}-services" ]
                ++ lib.optionals (inputs ? home-manager) [
                  outerConfig.nix2gpuHomeConfigurations.default.activationPackage
                ];
            };
        };
    };
}
