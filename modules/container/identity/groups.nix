{ config, lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.groups = mkOption {
    description = ''
      groups to place inside the generated nix2vast container.
    '';
    type = types.attrsOf config.types.groupDef;
    internal = true;
  };

  config.groups = {
    root.gid = 0;
    sshd.gid = 74;
    nobody.gid = 65534;
    nogroup.gid = 65534;
    nixbld.gid = 30000;
  };
}
