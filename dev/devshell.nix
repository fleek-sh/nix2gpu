{
  perSystem =
    {
      pkgs,
      inputs',
      config,
      ...
    }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          docker
          podman
          inputs'.nix2container.packages.skopeo-nix2container
          dive

          mkdocs
          config.pythonWithMkdocs

          vastai
          gh

          nix-fast-build
        ];
      };
    };
}
