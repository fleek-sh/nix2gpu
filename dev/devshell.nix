{
  perSystem =
    { pkgs, inputs', ... }:
    let
      pythonMkDocs = pkgs.python3.withPackages(ps: with ps; [
        mkdocs
        mkdocs-material
      ]);
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          docker
          podman
          inputs'.nix2container.packages.skopeo-nix2container
          dive

          mkdocs
          pythonMkDocs

          vastai
          gh

          nix-fast-build
        ];
      };
    };
}
