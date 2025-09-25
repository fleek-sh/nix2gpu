{ config, lib, ... }:
{
  options.nix2vast.nixConfig = lib.mkOption {
    description = ''
      a replacement nix.conf to use.
    '';
    type = config.types.textFilePackage;
    default = ./nix.conf;
  };
}
