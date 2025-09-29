{
  perContainer =
    { name, nix2vastConfig }:
    {
      perSystem =
        {
          pkgs,
          inputs',
          self',
          ...
        }:
        {
          packages."${name}-container" = inputs'.nix2container.packages.nix2container.buildImage {
            inherit (nix2vastConfig) name tag maxLayers;

            copyToRoot = nix2vastConfig.copyToRoot ++ nix2vastConfig.extraCopyToRoot;
            initializeNixDatabase = true;

            config = {
              entrypoint = [
                "${pkgs.tini}/bin/tini"
                "--"
                "${self'.packages.startupScript}/bin/startup.sh"
              ];

              Env = nix2vastConfig.env ++ nix2vastConfig.extraEnv;

              WorkingDir = nix2vastConfig.workingDir;
              User = nix2vastConfig.user;

              ExposedPorts = nix2vastConfig.exposedPorts;

              Labels = nix2vastConfig.labels ++ nix2vastConfig.extraLabels;
            };
          };
        };
    };
}
