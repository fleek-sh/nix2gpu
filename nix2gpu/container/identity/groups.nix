{ config, lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.nix2gpuGroups = mkOption {
    description = ''
      groups to place inside the generated nix2gpu container.
    '';
    type = types.attrsOf config.nix2gpuTypes.groupDef;
    internal = true;
  };

  config.nix2gpuGroups = {
    root.gid = 0;
    sshd.gid = 74;
    nobody.gid = 65534;
    nogroup.gid = 65534;
    nixbld.gid = 30000;
  };
}
