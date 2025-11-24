{ config, lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.nix2vastGroups = mkOption {
    description = ''
      groups to place inside the generated nix2vast container.
    '';
    type = types.attrsOf config.nix2vastTypes.groupDef;
    internal = true;
  };

  config.nix2vastGroups = {
    root.gid = 0;
    sshd.gid = 74;
    nobody.gid = 65534;
    nogroup.gid = 65534;
    nixbld.gid = 30000;
  };
}
