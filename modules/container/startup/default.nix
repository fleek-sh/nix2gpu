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
          extraStartupScript = pkgs.writeShellApplication {
            name = "extra-startup-script";
            runtimeInputs = container.options.systemPackages;
            text = outerConfig.nix2gpu.${container.name}.extraStartupScript;
          };
        in
        {
          startupScript =
            pkgs.resholve.writeScriptBin "${container.name}-startup.sh"
              {
                interpreter = lib.getExe pkgs.bash;
                inputs = config.environment.allPkgs ++ [ extraStartupScript ];
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

                extra-startup-script
              '';
        };
    };
}
