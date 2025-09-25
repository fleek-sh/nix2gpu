{ config, ... }:
{
  options.nix2vast.perSystem =
    { pkgs, ... }:
    {
      nixConfig = pkgs.mkOption {
        description = ''
          a replacement nix.conf to use.
        '';
        type = config.types.textFilePackage;
        default = ./nix.conf;
      };
    };
}
