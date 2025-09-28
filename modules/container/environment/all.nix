{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.allPkgs = pkgs.symlinkJoin {
        name = "all-pkgs";
        paths = with self'.packages; [
          corePkgs
          networkPkgs
          devPkgs
          cudaEnv
          container-services
        ];
      };
    };
}
