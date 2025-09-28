{
  perSystem =
    { pkgs, self', ... }:
    {
      packages.baseSystem =
        pkgs.runCommand "base-system"
          {
            allowSubstitutes = false;
            preferLocalBuild = true;
          }
          ''
            exec ${self'.packages.createBaseSystem}/bin/create-system.sh
          '';
    };
}
