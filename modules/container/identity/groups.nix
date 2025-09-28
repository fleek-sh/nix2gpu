{ config, lib, ... }:
let
  inherit (lib) types;
in
{
  options.groups = lib.mkOption {
    description = ''
      groups to place inside the generated nix2vast container.
    '';
    type = types.attrsOf config.types.groupDef;
  };

  config.groups = {
    root.gid = 0;
    sshd.gid = 74;
    nobody.gid = 65534;
    nogroup.gid = 65534;
    nixbld.gid = 30000;
  };
}
