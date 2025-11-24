{
  perSystem =
    { pkgs, inputs', ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          docker
          podman
          inputs'.nix2container.packages.skopeo-nix2container
          dive

          vastai
          gh

          nix-fast-build
        ];
      };
    };
}
