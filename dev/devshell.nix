{
  perSystem =
    { pkgs, inputs', ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          docker
          podman

          gh

          inputs'.nix2container.packages.skopeo-nix2container

          dive

          age
          inputs'.agenix.packages.default

          nix-fast-build
        ];
      };
    };
}
