{
  lib,
  pkgs,
  inputs',
  name,
  ...
}:
let
  noShellExecutorError = ''
    Neither `docker` or `podman` could be found on path.

    Please install (and setup) one of them in order to run the shell locally.

    Podman does not require a root daemon, and
    can be included in a nix shell like so:

    ```nix
    pkgs.mkShell {
      packages = with pkgs; [
          podman
      ];
    };


    ```
    Docker can be installed via NixOS like so:
    ```nix
    virtualisation.docker.enable = true;
    ```

    For other systems please consult your own documentation.

    Source: `${./_shell.nix}`
  '';

  mkShell =
    shell:
    pkgs.resholve.writeScriptBin "${shell}-shell"
      {
        interpreter = lib.getExe pkgs.bash;
        inputs = [ inputs'.nix2container.packages.skopeo-nix2container ];
        fake = {
          external = [
            "docker"
            "podman"
          ];
        };
      }
      ''
        set -euo pipefail

        gum log --level debug "Starting ${shell} shell..."

        exec ${shell} run --rm -it \
          --gpus all \
          --cap-add=MKNOD \
          -v "$(pwd):/workspace" \
          -w /workspace \
          ${name}:latest \
          /bin/bash \
          "$@"
      '';
in
{
  scripts = rec {
    podmanShell = mkShell "podman";
    dockerShell = mkShell "docker";
    shell =
      pkgs.resholve.writeScriptBin "shell"
        {
          interpreter = lib.getExe pkgs.bash;
          execer = [
            "cannot:${lib.getExe podmanShell}"
            "cannot:${lib.getExe dockerShell}"
          ];
          inputs = [
            podmanShell
            dockerShell
          ]
          ++ (with pkgs; [
            which
            coreutils
            gum
          ]);
        }
        ''
          set -euo pipefail

          gum log --level debug "Locating a container runtime to launch shell with..."

          if which podman &>/dev/null; then
            exec podman-shell "$@"
          fi

          if which docker &>/dev/null; then
            exec docker-shell "$@"
          fi

          error_message="$(cat <<'EOF'
          ${noShellExecutorError}
          EOF
          )"

          gum log \
            --level error
            "$error_message"
        '';
  };
}
