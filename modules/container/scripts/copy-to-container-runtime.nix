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
  perSystem =
    { pkgs, self', ... }:
    {
      perContainer =
        { container, ... }:
        {
          scripts = {
            copyToContainerRuntime = pkgs.writeShellApplication {
              name = "copy-to-container-runtime";
              runtimeInputs = with self'.packages.${container.name}; [
                copyToPodman
                copyToDockerDaemon
              ];
              text = ''
                if which podman &>/dev/null; then
                  exec copy-to-podman "$@"
                fi

                if which docker &>/dev/null; then
                  exec copy-to-docker-daemon "$@"
                fi

                printf "\n\n\033[31mError:\033[0m %s\n\n\n" "$(cat <<'EOF'
                ${noRuntimeExecutorError}
                EOF
                )" >&2
              '';
            };
          };
        };
    };
}
