{
  description = "nix2vast - nixos containers optimized for vast.ai compute";

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { system, ... }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.hf-nix.overlays.default ];

            config = {
              cudaSupport = true; # the monopoly
              allowUnfree = true; # the price of admission
              rocmSupport = false; # the controlled opposition
            };
          };

          process-compose.container-services = {
            imports = [ inputs.services-flake.processComposeModules.default ];
          };
        };

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.process-compose-flake.flakeModule
        ./nix/flake-modules
      ];
    };

  inputs = {
    hf-nix.url = "github:huggingface/hf-nix";
    nixpkgs.follows = "hf-nix/nixpkgs";

    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "hf-nix/nixpkgs";
    };

    services-flake.url = "github:juspay/services-flake";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
