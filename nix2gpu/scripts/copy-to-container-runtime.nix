{
  lib,
  pkgs,
  self',
  name,
  ...
}:
let
  noRuntimeExecutorError = ''
    Neither `docker` or `podman` could be found on path.

    Please install (and setup) one of them in order to copy to
    that runtime locally.

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

    Source: `${./copy-to-container-runtime.nix}`
  '';
in
{
  scripts.copyToContainerRuntime =
    pkgs.resholve.writeScriptBin "copy-to-container-runtime"
      {
        interpreter = lib.getExe pkgs.bash;
        inputs =
          (with self'.packages.${name}; [
            copyToPodman
            copyToDockerDaemon
          ])
          ++ (with pkgs; [
            which
            coreutils
            gum
          ]);
        execer = [
          "cannot:${lib.getExe self'.packages.${name}.copyToPodman}"
          "cannot:${lib.getExe self'.packages.${name}.copyToDockerDaemon}"
        ];
      }
      ''
        set -euo pipefail

        gum log --level debug "Locating a container runtime to use"

        if which podman &>/dev/null; then
          gum log --level debug "Running on podman"
          exec copy-to-podman "$@"
        fi

        if which docker &>/dev/null; then
          gum log --level debug "Running with docker daemon"
          exec copy-to-docker-daemon "$@"
        fi

        error_message="$(cat <<'EOF'
        ${noRuntimeExecutorError}
        EOF
        )"

        gum log \
          --level error \
          "$error_message"
      '';
}
