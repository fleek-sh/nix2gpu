{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types;
in
{
  options.groupContents = flake-parts-lib.mkPerSystemOption {
    description = ''
      contents of /etc/group.
    '';
    type = types.str;
  };

  config.groupContents =
    perSystemArgs:
    let
      userCfg = config.users perSystemArgs;
      groupCfg = config.groups;

      groupMemberMap =
        let
          mappings = builtins.foldl' (
            acc: user:
            let
              userGroups = userCfg.${user}.groups or [ ];
            in
            acc ++ map (group: { inherit user group; }) userGroups
          ) [ ] (lib.attrNames userCfg);
        in
        builtins.foldl' (acc: v: acc // { ${v.group} = acc.${v.group} or [ ] ++ [ v.user ]; }) { } mappings;

      groupToGroup =
        k:
        { gid }:
        let
          members = groupMemberMap.${k} or [ ];
        in
        "${k}:x:${toString gid}:${lib.concatStringsSep "," members}";

      groups = (lib.attrValues (lib.mapAttrs groupToGroup groupCfg));
    in
    lib.concatStringsSep "\n" groups;
}
