{ lib, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  options.registries = mkOption {
    description = ''
      The container registries to push your images to.

      This option specifies a list of the full registry paths, including the repository
      and image name, where the container image will be pushed. This is a
      mandatory field if you intend to publish your images via `<container>.copyToGithub`.
    '';
    example = literalExpression ''
      registries = [ "ghcr.io/my-org/my-image" ];
    '';
    type = types.listOf types.str;
    default = [ ];
  };
}
