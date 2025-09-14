{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      nix2containerPkgs = inputs.nix2container.packages.${system};
      containerName = "nix2vast";
      registry = "ghcr.io/fleek-platform";
    in
    {
      apps = {
        load = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "nix2vast-load" ''
            echo "building and loading ${containerName}:latest..."
            nix run --impure .#default.copyToDockerDaemon
            echo "Loaded ${containerName}:latest to Docker"
          ''}/bin/nix2vast-load";
        };

        run = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "nix2vast-run" ''
            docker run --rm -it \
              --gpus all \
              -p 2222:22 \
              -e TAILSCALE_AUTHKEY=''${TAILSCALE_AUTHKEY:-} \
              ${containerName}:latest
          ''}/bin/nix2vast-run";
        };

        login = {
          type = "app";
          program = toString (
            pkgs.writeScript "nix2vast-login" ''
              #!${pkgs.bash}/bin/bash
              if ! ${pkgs.gh}/bin/gh auth status &>/dev/null; then
                echo "authenticating with github..."
                ${pkgs.gh}/bin/gh auth login --scopes write:packages
              fi
              TOKEN=$(${pkgs.gh}/bin/gh auth token)
              echo "$TOKEN" | ${pkgs.skopeo}/bin/skopeo login ghcr.io -u "$(${pkgs.gh}/bin/gh api user --jq .login)" --password-stdin
              echo "logged into ghcr.io..."
            ''
          );
        };

        push = {
          type = "app";
          program = toString (
            pkgs.writeScript "push" ''
              #!${pkgs.bash}/bin/bash
              set -euo pipefail

              # Ensure containers policy exists
              if [ ! -f "$HOME/.config/containers/policy.json" ]; then
                echo "Creating containers policy file..."
                mkdir -p "$HOME/.config/containers"
                cat > "$HOME/.config/containers/policy.json" << 'EOF'
              {
                "default": [
                  {
                    "type": "insecureAcceptAnything"
                  }
                ]
              }
              EOF
              fi

              # Check if logged in
              if ! ${pkgs.gh}/bin/gh auth status &>/dev/null; then
                echo "Not logged in. Run 'nix run .#login' first"
                exit 1
              fi

              echo "building image..."
              nix build --impure .#default

              TAG="$(date +%Y%m%d-%H%M%S)"
              REPO="${registry}"
              IMAGE="${containerName}:$TAG"

              # Get credentials from gh
              GITHUB_USER=$(${pkgs.gh}/bin/gh api user --jq .login)
              GITHUB_TOKEN=$(${pkgs.gh}/bin/gh auth token)

              echo "converting to tarball..."
              TARBALL=$(mktemp --suffix=.tar)
              ${nix2containerPkgs.skopeo-nix2container}/bin/skopeo --insecure-policy copy nix:$(readlink -f result) docker-archive:$TARBALL

              echo "pushing $IMAGE to $REPO..."
              ${pkgs.skopeo}/bin/skopeo copy \
                --insecure-policy \
                --dest-creds="$GITHUB_USER:$GITHUB_TOKEN" \
                docker-archive:$TARBALL \
                "docker://$REPO/$IMAGE"

              rm -f $TARBALL

              echo "Successfully pushed $REPO/$IMAGE"
              echo "Pull with: docker pull $REPO/$IMAGE"
            ''
          );
        };

        shell = {
          type = "app";
          program = "${pkgs.writeShellScriptBin "nix2vast-shell" ''
            docker run --rm -it \
              --gpus all \
              -v $(pwd):/workspace \
              -w /workspace \
              ${containerName}:latest \
              /bin/bash
          ''}/bin/nix2vast-shell";
        };
      };
    };
}
