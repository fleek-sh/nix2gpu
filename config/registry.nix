{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.registry = mkOption {
    description = ''
      The container registry to push your images to.

      This option specifies the full registry path, including the repository
      and image name, where the container image will be pushed. This is a
      mandatory field if you intend to publish your images via `<container>.copyToGithub`.
    '';
    example = ''
      registry = "ghcr.io/my-org/my-image";
    '';
    type = types.str;
    default = "";
  };
}
