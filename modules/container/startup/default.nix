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
          hasServices =
            inputs ? services-flake && inputs ? process-compose-flake && container.options ? services;
        in
        {
          startupScript =
            pkgs.resholve.writeScriptBin "${container.name}-startup.sh"
              {
                interpreter = lib.getExe pkgs.bash;
                inputs =
                  config.environment.allPkgs
                  ++ lib.optionals (inputs ? home-manager) [
                    outerConfig.nix2gpuHomeConfigurations.default.activationPackage
                  ];
                execer = [
                  "cannot:${lib.getExe' pkgs.openssh "ssh-keygen"}"
                  "cannot:${lib.getExe' pkgs.openssh "sshd"}"
                  "cannot:${lib.getExe' pkgs.tailscale "tailscaled"}"
                  "cannot:${lib.getExe' pkgs.tailscale "tailscale"}"
                  "cannot:${lib.getExe' pkgs.glibc "ldd"}"
                  "cannot:${lib.getExe self'.packages."${container.name}-services"}"
                ];
                keep = {
                  "/usr/bin/nvidia-smi" = true;
                };
                fake = {
                  external = [ "passwd" ];
                };
                prologue =
                  (pkgs.writeText "setup-passwd" ''
                    export PATH="${pkgs.shadow}/bin:$PATH"
                  '').outPath;
              }
              ''
                ${builtins.readFile ./startup.sh}

                ${lib.optionalString (inputs ? home-manager) ''
                  echo "[nix2gpu] activating home-manager..."
                  home-manager-generation
                ''}

                ${outerConfig.nix2gpu.${container.name}.extraStartupScript}

                ${
                  if hasServices then
                    ''
                      if [[ $- != *i* ]] || ! [ -t 0 ]; then
                        export PC_DISABLE_TUI=true
                      fi

                      echo "[nix2gpu] starting services..."
                      ${container.name}-services
                    ''
                  else
                    ''
                      echo "[nix2gpu] entering interactive terminal..."
                      sleep infinity
                    ''
                }
              '';
        };
    };
}
