{ config, lib, ... }:
let
  userToShadow = k: _: "${k}:!:19000:0:99999:7:::";
in
{
  flake.modules.shadowContents =
    { system, ... }:
    let
      shadows = lib.attrValues (lib.mapAttrs userToShadow config.${system}.users);
    in
    lib.concatStringsSep "\n" shadows;
}
