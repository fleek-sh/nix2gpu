{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options.profile = mkOption {
    description = ''
      nix2gpu generated nix store profile.
    '';
    type = types.package;
    internal = true;
  };

  config.profile = pkgs.buildEnv {
    name = "nix2gpu-profile";
    paths = [ config.environment.allPkgs ];
    pathsToLink = [
      "/bin"
      "/sbin"
      "/lib"
      "/libexec"
      "/share"
    ];
  };

  config.nimiSettings.container.copyToRoot = config.profile;
}
