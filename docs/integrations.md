# // integrations //

`nix2gpu` has a modular integration system with a number of flakes from the
nix ecosystem. These may be turned on at will and automatically by including any one of these
flakes inside your flake's `inputs`.

______________________________________________________________________

## // `nix2container` //

[`nix2container`](https://github.com/nlewo/nix2container) is an archive-less `dockerTools.buildImage` implementation which provides an efficient container workflow for building containers with Nix.

You may use it to generate your `nix2gpu` containers instead optionally by adding it to your `flake.nix`:

```nix
inputs.nix2container.url = "github:nlewo/nix2container";
```

______________________________________________________________________

## // `services-flake` //

[`services-flake`](https://github.com/juspay/services-flake) provides declarative, composable and reproducible services for Nix development environments. `nix2gpu` has an optional extension to allow:

- Managing in container services with `process-compose` as a lightweight alternative to `systemd`.
- Usage of custom AI related services like `ComfyUI`.

You may use it to manage your `nix2gpu` containers' services by adding it to your `flake.nix`:

```nix
inputs.services-flake.url = "github:juspay/services-flake";
inputs.process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
```

To configure your services, see the [services option](./options.md#persystemnix2gpucontainerservices) for more details.

______________________________________________________________________

## // `home-manager` //

[`home-manager`](https://github.com/nix-community/home-manager) allows you to manage a user environment using Nix, which might be useful for adding various tools and programs to a `nix2gpu` container in a
modular, declarative way.

You may use it to manage your `nix2gpu` containers' home directory by adding it to your `flake.nix`:

```nix
inputs.home-manager = {
  url = "github:nix-community/home-manager";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

To configure your home, see the [home option](./options.md#persystemnix2gpucontainerhome) for more details.

Since external home manager configurations often use an arbitrarily named user (i.e. `john` and not `root`), `nix2gpu` provides a convenient home manager module you can use to port an existing user's config to the `root` user, which is more common for use in containers:

```nix
nix2gpu."overridden-root" = {
  home = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        inputs.exampleHomeSource.homeModules.john
        inputs.nix2gpu.homeModules.force-root-user # Force the `john` specific module above to apply to root too
      ];
    };
};
```
