{ config, lib, ... }:
let
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
in
{
  flake.modules.perSystem =
    { system, ... }:
    {
      passwdContents = lib.concatStringsSep "\n" (
        lib.attrValues (lib.mapAttrs userToPasswd config.${system}.users)
      );
    };
}
