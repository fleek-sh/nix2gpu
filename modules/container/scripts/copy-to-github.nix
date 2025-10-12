{
  perSystem =
    { pkgs, inputs', ... }:
    {
      perContainer =
        { container, ... }:
        {
          scripts.copyToGithub = pkgs.writeShellApplication rec {
            name = "${container.name}-copy-to-github-registry";
            runtimeInputs = with pkgs; [
              gh
              inputs'.nix2container.packages.skopeo-nix2container
            ];
            text = ''
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
              if ! gh auth status &>/dev/null; then
                echo "Not logged in. Run 'nix run .#${container.name}.loginToGithub' first"
                exit 1
              fi

              echo "[nix2vast] building image..."
              nix build .#${container.name}

              TAG="$(date +%Y%m%d-%H%M%S)"
              REPO="${container.options.registry}"
              IMAGE="${container.name}:$TAG"

              if [[ -z "$REPO" ]]; then
                printf '\033[31mError:\033[0m %s.\n' 'In order to use `${name}` the `registry` attribute of your nix2vast container must be set' >&2
                exit 1
              fi

              # Get credentials from gh
              GITHUB_USER="$(gh api user --jq .login)"
              GITHUB_TOKEN="$(gh auth token)"

              echo "[nix2vast] converting to tarball..."
              TARBALL=$(mktemp --suffix=.tar)
              skopeo copy \
                --insecure-policy \
                nix:"$(readlink -f result)" \
                docker-archive:"$TARBALL"

              echo "[nix2vast] pushing $IMAGE to $REPO..."
              skopeo copy \
                --insecure-policy \
                --dest-creds="$GITHUB_USER:$GITHUB_TOKEN" \
                docker-archive:"$TARBALL" \
                "docker://$REPO/$IMAGE"

              rm -f "$TARBALL"

              echo "[nix2vast] successfully pushed $REPO/$IMAGE"
              echo "[nix2vast] pull with: docker pull $REPO/$IMAGE"
            '';
          };
        };
    };
}
