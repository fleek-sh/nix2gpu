{ config, lib, ... }:
let
  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";
in
{
  flake.modules.perSystem =
    { system, ... }:
    {
      shadowContents = lib.concatStringsSep "\n" (
        lib.attrValues (lib.mapAttrs userToShadow config.${system}.users)
      );
    };
}
