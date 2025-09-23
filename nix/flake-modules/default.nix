{
  imports = [
    ./scripts.nix
    ./container-passthru.nix
    ./services.nix
    ./devshell.nix
    ./fmt.nix
  ];

  flake.flakeModule = {pkgs, ...}: {
    nix2vast = {
      home = pkgs.mkOption {
        description = ''
        the [`home-manager`](https://github.com/nix-community/home-manager)
        configuration to use inside your `nix2vast` container.

        by default a minimal set of useful modern shell packages is
        included for hacking on your machines.
        '';
        # TODO: expose home-manager
      };
      services = pkgs.mkOption {
        description = ''
        the [`services-flake`](https://github.com/juspay/services-flake)
        configuration to use inside your `nix2vast` container.

        when your container is launched it boots into a
        [process-compose](https://github.com/F1bonacc1/process-compose]
        interface running all services specificed. 

        this can be useful for running your own web servers or things
        like nginx.
        '';
        # TODO: expose services
      };
      copyToRoot = pkgs.mkOption {
        description = ''
        extra packages to copy to the root of your container.
        '';
        # TODO: expose services
      };

      env = pkgs.mkOption {
        description = ''
          environment variables to set inside your container.
        '';
        # TODO: expose services
      };

      workingDir = pkgs.mkOption {
        description = ''
          the working directory for your container to start in.
        '';
        # TODO: expose services
      };

      user = pkgs.mkOption {
        description = ''
          the default user for your container.
        '';
        # TODO: expose services
      };

      exposedPorts = pkgs.mkOption {
        description = ''
          exposed ports for your container.
        '';
        # TODO: expose services
      };

      labels = pkgs.mkOption {
        description = ''
          container labels to set.
        '';
        # TODO: expose services
      };

      maxLayers = pkgs.mkOption {
        description = ''
          the maximum amount of layers to use when creating your container.
        '';
        # TODO: expose services
      };

      cudaPackages = pkgs.mkOption {
        description = ''
          the cuda packages source to use.

          this is useful for selecting a specific version
          on which your container relies.
        '';
        # TODO: expose services
      };

      sshdConfig = pkgs.mkOption {
        description = ''
          a replacement sshd configuration to use.
        '';
        # TODO: expose services
      };

      nixConf = pkgs.mkOption {
        description = ''
          a replacement nix.conf to use.
        '';
        # TODO: expose services
      };
 
      extraStartupScript = pkgs.mkOption {
        description = ''
          extra commands to run on container startup.
        '';
        # TODO: expose services
      };
    };
  };
}
