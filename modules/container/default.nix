{
  perSystem =
    {
      pkgs,
      inputs',
      self',
      ...
    }:
    {
      perContainer =
        { container, ... }:
        let
          inherit (container) name options;
        in
        {
          packages."${name}-container" = inputs'.nix2container.packages.nix2container.buildImage {
            inherit (options) name tag maxLayers;

            copyToRoot = options.copyToRoot ++ options.extraCopyToRoot;
            initializeNixDatabase = true;

            config = {
              entrypoint = [
                "${pkgs.tini}/bin/tini"
                "--"
                "${self'.packages.startupScript}/bin/startup.sh"
              ];

              Env = options.env ++ options.extraEnv;

              WorkingDir = options.workingDir;
              User = options.user;

              ExposedPorts = options.exposedPorts;

              Labels = options.labels ++ options.extraLabels;
            };
          };
        };
    };
}
