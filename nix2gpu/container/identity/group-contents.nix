{ config, lib, ... }:
let
  inherit (lib) types mkOption;
  rootConfig = config;
in
{
  options.nix2gpuGroupContents = mkOption {
    description = ''
      contents of /etc/group.
    '';
    type = types.str;
    internal = true;
  };

  config.nix2gpuGroupContents =
    let
      groupMemberMap =
        let
          mappings = builtins.foldl' (
            acc: user:
            let
              userGroups = config.users.${user}.groups or [ ];
            in
            acc ++ map (group: { inherit user group; }) userGroups
          ) [ ] (lib.attrNames config.nix2gpuUsers);
        in
        builtins.foldl' (acc: v: acc // { ${v.group} = acc.${v.group} or [ ] ++ [ v.user ]; }) { } mappings;

      groupToGroup =
        k:
        { gid }:
        let
          members = groupMemberMap.${k} or [ ];
        in
        "${k}:x:${toString gid}:${lib.concatStringsSep "," members}";

      groups = lib.attrValues (lib.mapAttrs groupToGroup rootConfig.nix2gpuGroups);
    in
    lib.concatStringsSep "\n" groups;
}
