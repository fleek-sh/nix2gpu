{ config, ... }:
{
  perSystem =
    { pkgs, ... }@perSystemArgs:
    {
      packages.profile = pkgs.buildEnv {
        name = "nix2vast-profile";
        paths = config.allPkgs perSystemArgs;
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
