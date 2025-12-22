{
  perSystem.perContainer =
    { config, container, ... }:
    {
      environment.allPkgs =
        config.environment.corePkgs
        ++ config.environment.networkPkgs
        ++ config.environment.devPkgs
        ++ config.environment.cudaEnv
        ++ container.options.systemPackages;
    };
}
