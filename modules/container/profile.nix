{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.profile = pkgs.buildEnv {
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
