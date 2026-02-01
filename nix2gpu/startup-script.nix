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
  options = {
    startupScript = mkOption {
      description = ''
        nix2gpu container ${name} startup script.
      '';
      type = types.package;
      internal = true;
    };

    copyToRootEnv = mkOption {
      description = ''
        Path to the merged copyToRoot environment used for populating
        /etc and /root in bubblewrap mode.
      '';
      type = types.path;
      default = "";
    };
  };

  config = {
    systemPackages = with pkgs; [ gum ];
    nimiSettings.startup.runOnStartup = lib.getExe (
      pkgs.resholve.writeScriptBin "${name}-startup.sh"
        {
          interpreter = lib.getExe pkgs.bash;
          inputs = config.systemPackages ++ [ extraStartupScript ];
          execer = [
            "cannot:${lib.getExe' pkgs.openssh "ssh-keygen"}"
            "cannot:${lib.getExe' pkgs.tailscale "tailscaled"}"
            "cannot:${lib.getExe' pkgs.tailscale "tailscale"}"
            "cannot:${lib.getExe' pkgs.glibc "ldd"}"
            "cannot:${lib.getExe pkgs.gum}"
          ];
          keep = {
            "/usr/bin/nvidia-smi" = true;
          };
          fake = {
            external = [ "passwd" ];
          };
          prologue =
            (pkgs.writeText "setup-env" ''
              export PATH="${pkgs.shadow}/bin:$PATH"
              export NIX2GPU_COPY_TO_ROOT="${config.copyToRootEnv}"
            '').outPath;
        }
        ''
          ${builtins.readFile ./startup-script/startup.sh}

          extra-startup-script
        ''
    );
  };
}
