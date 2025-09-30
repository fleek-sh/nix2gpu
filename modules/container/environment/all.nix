{
  perSystem =
    {
      config,
      self',
      pkgs,
      ...
    }:
    let
      includedEnv = with config.environment; [
        corePkgs
        networkPkgs
        devPkgs
        cudaEnv
      ];

      includedPkgs = with self'.packages; [ container-services ];
    in
    {
      environment.allPkgs = pkgs.symlinkJoin {
        name = "all-pkgs";
        paths = includedEnv ++ includedPkgs;
      };
    };
}
