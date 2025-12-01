{
  config,
  lib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.perContainer = config.flake.lib.mkPerContainerOption (
      { container, ... }:
      {
        options.baseSystem = mkOption {
          description = ''
            nix2gpu generated baseSystem for ${container.name}.
          '';
          type = types.package;
          internal = true;
        };
      }
    );
  });

  config.perSystem =
    { pkgs, config, ... }:
    {
      perContainer =
        { container, ... }:
        let
          script = pkgs.replaceVars ./create-base-system.sh {
            inherit (container.options) sshdConfig nixConfig;

            inherit (config) nix2gpuPasswdContents nix2gpuGroupContents nix2gpuShadowContents;

            inherit (pkgs)
              bashInteractive
              coreutils-full
              glibc
              cacert
              ;

            glibcBin = pkgs.glibc.bin;
          };
        in
        {
          baseSystem = pkgs.runCommandLocal "base-system" {
            nativeBuildInputs = with pkgs; [
              bashInteractive
              coreutils-full
              glibc
              cacert
            ];
          } (builtins.readFile script);
        };
    };
}
