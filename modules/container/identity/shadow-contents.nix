{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types;

  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";
in
{
  options.shadowContents = flake-parts-lib.mkPerSystemOption {
    description = ''
      contents of /etc/shadow.
    '';
    type = types.str;
    internal = true;
  };

  config.shadowContents =
    perSystemArgs:
    let
      userCfg = config.users perSystemArgs;
      shadows = lib.attrValues (lib.mapAttrs userToShadow userCfg);
    in
    lib.concatStringsSep "\n" shadows;
}
