{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (_: {
    options.profile = mkOption {
      description = ''
        nix2vast generated nix store profile.
      '';
      type = types.package;
      internal = true;
    };
  });

  config.perSystem =
    { pkgs, self', ... }:
    {
      profile = pkgs.buildEnv {
        name = "nix2vast-profile";
        paths = [ self'.packages.allPkgs ];
        pathsToLink = [
          "/bin"
          "/sbin"
          "/lib"
          "/libexec"
          "/share"
        ];
      };

    };
}
