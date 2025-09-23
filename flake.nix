{
  description = "nix2vast - nixos containers optimized for vast.ai compute";

  outputs =
    inputs@{ flake-parts, self, ... }:
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

      flake = {
        homeConfigurations.default = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          extraSpecialArgs = {
            inherit inputs;
            nix2vast = self.packages.x86_64-linux;
          };
          modules = [
            inputs.agenix.homeManagerModules.default
            self.homeModules.default
          ];
        };

        homeModules.default =
          { ... }:
          {
            imports = [ ./nix/home ];

            home.stateVersion = "25.11";
            home.username = "root";
            home.homeDirectory = "/root";
          };
      };

      imports = [
        inputs.treefmt-nix.flakeModule
        inputs.process-compose-flake.flakeModule
        inputs.home-manager.flakeModules.home-manager
        ./nix/flake-modules
      ];

    };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://cache.garnix.io"
      "https://huggingface.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "huggingface.cachix.org-1:ynTPbLS0W8ofXd9fDjk1KvoFky9K2jhxe6r4nXAkc/o="
    ];
  };

  inputs = {
    hf-nix.url = "github:huggingface/hf-nix";
    nixpkgs.follows = "hf-nix/nixpkgs";

    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "hf-nix/nixpkgs";
    };

    services-flake.url = "github:juspay/services-flake";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
