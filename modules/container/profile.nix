{ config, ... }:
{
  flake.modules.profile =
    { pkgs, ... }@perSystemArgs:
    pkgs.buildEnv {
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
}
