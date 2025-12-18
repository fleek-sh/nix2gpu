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

    Source: `${./shell.nix}`
  '';
in
{
  perSystem =
    { pkgs, inputs', ... }:
    {
      perContainer =
        { container, ... }:
        let
          mkShell =
            shell:
            pkgs.writeShellApplication {
              name = "${shell}-shell";
              runtimeInputs = [ inputs'.nix2container.packages.skopeo-nix2container ];
              text = ''
                echo "[nix2gpu] starting ${shell} shell..."

                exec ${shell} run --rm -it \
                  --gpus all \
                  --cap-add=MKNOD \
                  -v "$(pwd):/workspace" \
                  -w /workspace \
                  ${container.name}:latest \
                  /bin/bash \
                  "$@"
              '';
            };
        in
        {
          scripts = rec {
            podmanShell = mkShell "podman";
            dockerShell = mkShell "docker";
            shell = pkgs.writeShellApplication {
              name = "shell";
              runtimeInputs = [
                podmanShell
                dockerShell
              ];
              text = ''
                if which podman &>/dev/null; then
                  exec podman-shell "$@"
                fi

                if which docker &>/dev/null; then
                  exec docker-shell "$@"
                fi

                printf "\n\n\033[31mError:\033[0m %s\n\n\n" "$(cat <<'EOF'
                ${noShellExecutorError}
                EOF
                )" >&2
              '';
            };
          };
        };
    };
}
