{ lib, ... }:
{
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      perContainer =
        { container, ... }:
        {
          scripts.copyToGithub =
            pkgs.resholve.writeScriptBin "${container.name}-copy-to-github-registry"
              {
                interpreter = lib.getExe pkgs.bash;
                inputs = with pkgs; [
                  gh
                  inputs'.nix2container.packages.skopeo-nix2container
                  coreutils
                ];
                execer = [
                  "cannot:${lib.getExe pkgs.gh}"
                  "cannot:${lib.getExe inputs'.nix2container.packages.skopeo-nix2container}"
                ];
              }
              ''
                set -euo pipefail

                if ! gh auth status &>/dev/null; then
                  echo "[nix2gpu] please log in to github first"
                  gh auth login --scopes write:packages
                fi

                ${lib.optionalString (container.options.registries == [ ]) ''
                  printf '\n\033[31mError:\033[0m %s.\n' 'In order to use "copyToGithub" the "registry" attribute of your nix2gpu container (${container.name}) must be set' >&2
                  exit 1
                ''}

                # shellcheck disable=SC2043,SC2016
                for registry in ${builtins.concatStringsSep " " container.options.registries}; do
                  IMAGE="${container.name}:${container.options.tag}"

                  GITHUB_USER="$(gh api user --jq .login)"
                  GITHUB_TOKEN="$(gh auth token)"

                  echo "[nix2gpu] pushing $IMAGE to $registry..."
                  skopeo copy \
                    --insecure-policy \
                    --dest-creds="$GITHUB_USER:$GITHUB_TOKEN" \
                    nix:"$(readlink -f ${self'.packages.${container.name}})" \
                    "docker://$registry/$IMAGE"

                  echo "[nix2gpu] successfully pushed $registry/$IMAGE"
                  echo "[nix2gpu] pull with: docker pull $registry/$IMAGE"
                done
              '';
        };
    };
}
