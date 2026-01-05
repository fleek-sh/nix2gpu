{
  lib,
  self',
  name,
  inputs',
  pkgs,
  config,
  ...
}:
let
  skopeo = inputs'.nix2container.packages.skopeo-nix2container;
in
{
  scripts.copyToGithub =
    pkgs.resholve.writeScriptBin "copy-to-github-registries"
      {
        interpreter = lib.getExe pkgs.bash;
        inputs = [
          pkgs.gh
          pkgs.coreutils
          skopeo
        ];
        execer = [
          "cannot:${lib.getExe pkgs.gh}"
          "cannot:${lib.getExe skopeo}"
        ];
      }
      ''
        set -euo pipefail

        if [ "$#" -lt 1 ]; then
          echo "Too little arguments provided"
          echo "Usage: copy-to-github-registries <registries>"
          exit 1
        fi

        registries="$1"

        if ! gh auth status &>/dev/null; then
          echo "[nix2gpu] please log in to github first"
          gh auth login --scopes write:packages
        fi

        # shellcheck disable=SC2043,SC2016
        for registry in $registries; do
          IMAGE="${name}:${config.tag}"

          GITHUB_USER="$(gh api user --jq .login)"
          GITHUB_TOKEN="$(gh auth token)"

          echo "[nix2gpu] pushing $IMAGE to $registry..."
          skopeo copy \
            --insecure-policy \
            --dest-creds="$GITHUB_USER:$GITHUB_TOKEN" \
            nix:"$(readlink -f ${self'.packages.${name}})" \
            "docker://$registry/$IMAGE"

          echo "[nix2gpu] successfully pushed $registry/$IMAGE"
          echo "[nix2gpu] pull with: docker pull $registry/$IMAGE"
        done
      '';
}
