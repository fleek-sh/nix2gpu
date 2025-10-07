{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.maxLayers = mkOption {
    description = ''
      the maximum amount of layers to use when creating your container.
    '';
    type = types.int;
    default = 50;
  };
}
