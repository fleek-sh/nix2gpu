{ config, lib, ... }:
let
  inherit (lib) types;
in
{
  options.nix2vast.registry = lib.mkOption {
    description = ''
      the container registry to push your images to.
    '';
    type = types.str;
  };

  config.flake.modules.scripts.perSystem =
    { pkgs, system, ... }:
    {
      copyToGithub = pkgs.writeShellApplication {
        name = "copy-to-github-registry";
        runtimeInputs = with pkgs; [
          gh
          config.nix2containerPkgs.skopeo-nix2container
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
            echo "Not logged in. Run 'nix run .#container.loginToGithub' first"
            exit 1
          fi

          echo "building image..."
          nix build .#container

          TAG="$(date +%Y%m%d-%H%M%S)"
          REPO="${config.nix2vast.${system}.registry}"
          IMAGE="${config.nix2vast.${system}.name}:$TAG"

          # Get credentials from gh
          GITHUB_USER=$(gh api user --jq .login)
          GITHUB_TOKEN=$(gh auth token)

          echo "converting to tarball..."
          TARBALL=$(mktemp --suffix=.tar)
          skopeo copy \
            --insecure-policy \
            nix:$(readlink -f result) \
            docker-archive:$TARBALL

          echo "pushing $IMAGE to $REPO..."
          skopeo copy \
            --insecure-policy \
            --dest-creds="$GITHUB_USER:$GITHUB_TOKEN" \
            docker-archive:$TARBALL \
            "docker://$REPO/$IMAGE"

          rm -f $TARBALL

          echo "Successfully pushed $REPO/$IMAGE"
          echo "Pull with: docker pull $REPO/$IMAGE"
        '';
      };
    };
}
