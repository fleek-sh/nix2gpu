{
  config,
  lib,
  name,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption;

  extraStartupScript = pkgs.writeShellApplication {
    name = "extra-startup-script";
    runtimeInputs = config.systemPackages;
    text = config.extraStartupScript;
  };
in
{
  options.startupScript = mkOption {
    description = ''
      nix2gpu container ${name} startup script.
    '';
    type = types.package;
    internal = true;
  };

  config.startupScript =
    pkgs.resholve.writeScriptBin "${name}-startup.sh"
      {
        interpreter = lib.getExe pkgs.bash;
        inputs = config.environment.allPkgs ++ [ extraStartupScript ];
        execer = [
          "cannot:${lib.getExe' pkgs.openssh "ssh-keygen"}"
          "cannot:${lib.getExe' pkgs.openssh "sshd"}"
          "cannot:${lib.getExe' pkgs.tailscale "tailscaled"}"
          "cannot:${lib.getExe' pkgs.tailscale "tailscale"}"
          "cannot:${lib.getExe' pkgs.glibc "ldd"}"
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
        ${builtins.readFile ./startup-script/startup.sh}

        extra-startup-script
      '';
}
