# // integrations //

`nix2gpu` ships its integrations as part of the flake. You do not enable them by
adding extra inputs upstream; if you are using the `nix2gpu` flake, they are
already available.

______________________________________________________________________

## // `Nimi` (modular services) //

[`Nimi`](https://github.com/weyl-ai/nimi) is the runtime that powers services in
`nix2gpu`. It runs [NixOS modular services](https://nixos.org/manual/nixos/unstable/#modular-services)
(Nix 25.11) without requiring a full init system.

- Define services under `services.<name>` using modular service modules.
- Tune runtime behavior with `nimiSettings` (restart, logging, startup).

See [services & runtime](./services.md) for the workflow and examples.

______________________________________________________________________

## // `nix2container` //

`nix2gpu` builds OCI images through `Nimi`'s `mkContainerImage`, which uses
[`nix2container`](https://github.com/nlewo/nix2container) under the hood. You do
not need to add a separate `nix2container` input to use `nix2gpu` containers.

______________________________________________________________________

## // `home-manager` //

[`home-manager`](https://github.com/nix-community/home-manager) is integrated
for user environment configuration. Use the `home` option to describe shell
configuration, tools, and dotfiles in a modular way.

If you are porting an existing home-manager config that targets a non-root user,
`nix2gpu` includes a convenience module:

```nix
inputs.nix2gpu.homeModules.force-root-user
```

See the [home option](./options.md#persystemnix2gpucontainerhome) for details.
