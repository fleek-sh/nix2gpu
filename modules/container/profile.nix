{ config, ... }:
{
  flake.modules.profile.perSystem =
    { pkgs, system, ... }:
    pkgs.buildEnv {
      name = "nix2vast-profile";
      paths = config.${system}.allPkgs;
      pathsToLink = [
        "/bin"
        "/sbin"
        "/lib"
        "/libexec"
        "/share"
      ];
    };
}
