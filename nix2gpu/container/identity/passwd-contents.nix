{ lib, config, ... }:
let
  inherit (lib) types mkOption;

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
  options.nix2gpuPasswdContents = mkOption {
    description = ''
      contents of /etc/passwd.
    '';
    type = types.str;
    internal = true;
  };

  config.nix2gpuPasswdContents =
    let
      users = lib.attrValues (lib.mapAttrs userToPasswd config.nix2gpuUsers);
    in
    lib.concatStringsSep "\n" users;
}
