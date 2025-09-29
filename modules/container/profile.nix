{ lib, flake-parts-lib, ... }:
let
  inherit (lib) types;
in
{
  options.profile = flake-parts-lib.mkPerSystemOption {
    description = ''
      nix2vast generated nix store profile.
    '';
    type = types.package;
    internal = true;
  };

  config.profile =
    { pkgs, self', ... }:
    pkgs.buildEnv {
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
}
