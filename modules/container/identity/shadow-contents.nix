{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;

  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.shadowContents = mkOption {
      description = ''
        contents of /etc/shadow.
      '';
      type = types.str;
      internal = true;
    };
  });

  config.perSystem =
    { config, ... }:
    {
      shadowContents =
        let
          userCfg = config.users;
          shadows = lib.attrValues (lib.mapAttrs userToShadow userCfg);
        in
        lib.concatStringsSep "\n" shadows;
    };

}
