{ lib, ... }:
let
  inherit (lib) types mkOption literalExpression;
in
{
  _class = "nix2gpu";

  options.tag = mkOption {
    description = ''
      The tag to use for your container image.

      This option specifies the tag that will be applied to the container
      image when it is built and pushed to a registry. Tags are used to
      version and identify different builds of your image.

      The default value is "latest", which is a common convention for the most
      recent build. However, it is highly recommended to use more descriptive
      tags for production images, such as version numbers or git commit hashes.
    '';
    example = literalExpression ''
      tag = "v1.2.3";
    '';
    type = types.str;
    default = "latest";
  };
}
