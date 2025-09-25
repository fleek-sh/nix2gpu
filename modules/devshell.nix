{
  config,
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      nix2containerPkgs = config.perSystem.nix2containerPkgs;
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
