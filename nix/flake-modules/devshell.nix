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
          docker
          podman

          gh

          nix2containerPkgs.skopeo-nix2container

          dive

          age
          inputs.agenix.packages.${system}.default
        ];
      };
    };
}
