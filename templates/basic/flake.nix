{
  description = "Basic nix2gpu template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nix2gpu = {
      url = "github:fleek-sh/nix2gpu";
      inputs.flake-parts.url = "flake-parts";
      inputs.systems.url = "systems";
      inputs.nixpkgs.url = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      systems,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ./default.nix ];
      systems = import systems;

      perSystem =
        { system, ... }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config = {
              cudaSupport = true;
              allowUnfree = true;
            };
          };
        };
    };
}
