{ lib, flake-parts-lib, ... }:
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
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.nix2vastPasswdContents = mkOption {
      description = ''
        contents of /etc/passwd.
      '';
      type = types.str;
      internal = true;
    };
  });

  config.perSystem =
    { config, ... }:
    {
      nix2vastPasswdContents =
        let
          users = lib.attrValues (lib.mapAttrs userToPasswd config.nix2vastUsers);
        in
        lib.concatStringsSep "\n" users;
    };
}
