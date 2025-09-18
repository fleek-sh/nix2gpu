{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      nix2containerPkgs = inputs.nix2container.packages.${system};
      containerName = "nix2vast";
      registry = "ghcr.io/fleek-platform";

      writeSkopeoApplication =
        name: text:
        pkgs.writeShellApplication {
          inherit name text;
          runtimeInputs = [
            pkgs.jq
            nix2containerPkgs.skopeo-nix2container
          ];
          excludeShellChecks = [ "SC2068" ];
        };

      mkShell =
        shell:
        writeSkopeoApplication "nix2vast-shell-${shell}" ''
          ${shell} run --rm -it \
            --gpus all \
            -v "$(pwd):/workspace" \
            -w /workspace \
            ${containerName}:latest \
            /bin/bash
        '';
    in
    {
      packages.loginToGithub = writeSkopeoApplication "login-to-github-registry" ''
        if ! ${pkgs.gh}/bin/gh auth status &>/dev/null; then
          echo "authenticating with github..."
          ${pkgs.gh}/bin/gh auth login --scopes write:packages
        fi
        TOKEN=$(${pkgs.gh}/bin/gh auth token)
        echo "$TOKEN" | ${pkgs.skopeo}/bin/skopeo login ghcr.io -u "$(${pkgs.gh}/bin/gh api user --jq .login)" --password-stdin
        echo "logged into ghcr.io..."
      '';

      packages.copyToGithub = writeSkopeoApplication "push-to-github-registry" ''
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
        nix build .#container

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
      '';

      packages = {
        dockerShell = mkShell "docker";
        podmanShell = mkShell "podman";
      };
    };
}
