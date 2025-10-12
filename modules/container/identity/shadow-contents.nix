{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;

  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.nix2vastShadowContents = mkOption {
      description = ''
        contents of /etc/shadow.
      '';
      type = types.str;
      internal = true;
    };
  });

  config = {
    transposition.nix2vastShadowContents = { };

    perSystem =
      { config, ... }:
      {
        nix2vastShadowContents =
          let
            userCfg = config.nix2vastUsers;
            shadows = lib.attrValues (lib.mapAttrs userToShadow userCfg);
          in
          lib.concatStringsSep "\n" shadows;
      };
  };

}
