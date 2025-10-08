{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.maxLayers = mkOption {
    description = ''
      The maximum number of layers to use when creating the container image.

      This option sets the upper limit on the number of layers that will be
      used to build the container image. This is an important consideration
      for caching and build time purposes, and can have many benefits.

      See [this blog post](https://grahamc.com/blog/nix-and-layered-docker-images/) 
      for some nice information on layers in a nix context.

      > This is a direct mapping to the
      > [`maxLaybers`](https://github.com/nlewo/nix2container?tab=readme-ov-file#nix2containerbuildimage)
      > attribute from [`nix2container`](https://github.com/nlewo/nix2container).
    '';
    example = ''
      maxLayers = 100;
    '';
    type = types.int;
    default = 50;
  };
}
