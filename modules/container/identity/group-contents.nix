{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
  rootConfig = config;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.groupContents = mkOption {
      description = ''
        contents of /etc/group.
      '';
      type = types.str;
      internal = true;
    };
  });

  config = {
    transposition.groupContents = { };

    perSystem =
      { config, ... }:
      {
        groupContents =
          let
            groupMemberMap =
              let
                mappings = builtins.foldl' (
                  acc: user:
                  let
                    userGroups = config.users.${user}.groups or [ ];
                  in
                  acc ++ map (group: { inherit user group; }) userGroups
                ) [ ] (lib.attrNames config.users);
              in
              builtins.foldl' (acc: v: acc // { ${v.group} = acc.${v.group} or [ ] ++ [ v.user ]; }) { } mappings;

            groupToGroup =
              k:
              { gid }:
              let
                members = groupMemberMap.${k} or [ ];
              in
              "${k}:x:${toString gid}:${lib.concatStringsSep "," members}";

            groups = lib.attrValues (lib.mapAttrs groupToGroup rootConfig.groups);
          in
          lib.concatStringsSep "\n" groups;
      };
  };

}
