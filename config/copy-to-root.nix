{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  inherit (config) systemConfig name;
in
{
  options.copyToRoot = mkOption {
    description = ''
      packages to copy to the root of your container.

      looking to install packages without effecting the
      default set? see `extraCopyToRoot`.
    '';
    type = types.listOf types.package;
    default = with systemConfig; [
      allContainers.${name}.baseSystem
      allContainers.${name}.profile
      nixStoreProfile
    ];
  };
}
