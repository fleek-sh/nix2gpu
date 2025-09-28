{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types;

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
  options.passwdContents = flake-parts-lib.mkPerSystemOption {
    description = ''
      contents of /etc/passwd.
    '';
    type = types.str;
  };

  config.passwdContents =
    perSystemArgs:
    let
      userCfg = config.users perSystemArgs;
      users = lib.attrValues (lib.mapAttrs userToPasswd userCfg);
    in
    lib.concatStringsSep "\n" users;
}
