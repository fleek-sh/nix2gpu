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
    options.perContainer = config.flake.lib.mkPerContainerOption (_: {
      options.profile = mkOption {
        description = ''
          nix2vast generated nix store profile.
        '';
        type = types.package;
        internal = true;
      };
    });
  });

  config.perSystem =
    { pkgs, ... }:
    {
      perContainer =
        { config, ... }:
        {
          profile = pkgs.buildEnv {
            name = "nix2vast-profile";
            paths = [ config.environment.allPkgs ];
            pathsToLink = [
              "/bin"
              "/sbin"
              "/lib"
              "/libexec"
              "/share"
            ];
          };

        };
    };

}
