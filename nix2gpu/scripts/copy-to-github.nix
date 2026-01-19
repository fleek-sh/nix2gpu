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
        inputs =
          with pkgs;
          [
            gh
            coreutils
            gum
          ]
          ++ [ skopeo ];
        execer = [
          "cannot:${lib.getExe pkgs.gh}"
          "cannot:${lib.getExe skopeo}"
          "cannot:${lib.getExe pkgs.gum}"
        ];
      }
      ''
        set -euo pipefail

        if ! gh auth status &>/dev/null; then
          gum log --level info "Please log in to GitHub first"
          gh auth login --scopes write:packages
        fi

        ${lib.optionalString (config.registries == [ ]) ''
          gum log \
            --level error \
            "In order to use \"copyToGithub\" the \"registries\" attribute of your nix2gpu container (${name}) must be set."

          exit 1
        ''}

        # shellcheck disable=SC2043,SC2016
        for registry in ${builtins.concatStringsSep " " config.registries}; do
          IMAGE="${name}:${config.tag}"

          GITHUB_USER="$(gh api user --jq .login)"
          GITHUB_TOKEN="$(gh auth token)"

          gum log --level debug "Pushing $IMAGE to $registry..."

          skopeo copy \
            --insecure-policy \
            --dest-creds="$GITHUB_USER:$GITHUB_TOKEN" \
            nix:"$(readlink -f ${self'.packages.${name}})" \
            "docker://$registry/$IMAGE"

          gum log --level debug "Successfully pushed $registry/$IMAGE"
          gum log --level debug "Pull with: docker pull $registry/$IMAGE"
        done
      '';
}
