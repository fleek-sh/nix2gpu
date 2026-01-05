{ lib, config, ... }:
let
  inherit (lib) types mkOption;

  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";
in
{
  options.nix2gpuShadowContents = mkOption {
    description = ''
      contents of /etc/shadow.
    '';
    type = types.str;
    internal = true;
  };

  config.nix2gpuShadowContents =
    let
      userCfg = config.nix2gpuUsers;
      shadows = lib.attrValues (lib.mapAttrs userToShadow userCfg);
    in
    lib.concatStringsSep "\n" shadows;
}
