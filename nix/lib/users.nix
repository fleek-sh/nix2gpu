{ lib, pkgs }:
let
  users = {
    root = {
      uid = 0;
      gid = 0;
      shell = "${pkgs.bashInteractive}/bin/bash";
      home = "/root";
      groups = [ "root" ];
      description = "System administrator";
    };

    sshd = {
      uid = 74;
      gid = 74;
      shell = "${pkgs.shadow}/bin/nologin";
      home = "/var/empty";
      groups = [ "sshd" ];
      description = "SSH daemon";
    };

    nobody = {
      uid = 65534;
      gid = 65534;
      shell = "${pkgs.shadow}/bin/nologin";
      home = "/var/empty";
      groups = [ "nobody" ];
      description = "Unprivileged account";
    };
  }
  // lib.listToAttrs (
    map (n: {
      name = "nixbld${toString n}";
      value = {
        uid = 30000 + n;
        gid = 30000;
        groups = [ "nixbld" ];
        shell = "${pkgs.shadow}/bin/nologin";
        home = "/var/empty";
        description = "Nix build user ${toString n}";
      };
    }) (lib.lists.range 1 32)
  );

  groups = {
    root.gid = 0;
    sshd.gid = 74;
    nobody.gid = 65534;
    nixbld.gid = 30000;
  };

  userToPasswd =
    k:
    {
      uid,
      gid ? 65534,
      home ? "/var/empty",
      description ? "",
      shell ? "/bin/false",
      ...
    }:
    "${k}:x:${toString uid}:${toString gid}:${description}:${home}:${shell}";

  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";

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
in
{
  inherit users groups;
  passwdContents = lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs userToPasswd users));
  shadowContents = lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs userToShadow users));
  groupContents = lib.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs groupToGroup groups));
}
