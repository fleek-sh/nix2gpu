{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      nix2containerPkgs = inputs.nix2container.packages.${system};
    in
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nix2containerPkgs.skopeo-nix2container
          skopeo
          dive
          docker
          podman
          gh
        ];
      };
    };
}
