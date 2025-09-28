{ config, lib, ... }:
{
  flake.modules.groupContents =
    { system, ... }:
    let
      users = config.${system}.users;

      groupMemberMap =
        let
          mappings = builtins.foldl' (
            acc: user:
            let
              userGroups = users.${user}.groups or [ ];
            in
            acc ++ map (group: { inherit user group; }) userGroups
          ) [ ] (lib.attrNames users);
        in
        builtins.foldl' (acc: v: acc // { ${v.group} = acc.${v.group} or [ ] ++ [ v.user ]; }) { } mappings;

      groupToGroup =
        k:
        { gid }:
        let
          members = groupMemberMap.${k} or [ ];
        in
        "${k}:x:${toString gid}:${lib.concatStringsSep "," members}";

      groups = (lib.attrValues (lib.mapAttrs groupToGroup config.groups));
    in
    lib.concatStringsSep "\n" groups;
}
