# // defining a custom service //

if you want to say, for example, run a custom backend process i.e. your
web server that interacts with/requires a cuda environment, then
you'll want to define a custom service module.

this guide describes how that would be done.

______________________________________________________________________

# // enabling services generation //

To enable generation and spawning of services from inside your `nix2gpu` container,
add the following to your `flake.nix`:

```nix
inputs.services-flake.url = "github:juspay/services-flake";
inputs.process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
```

______________________________________________________________________

# // example: adding a service for `pkgs.http-server` //

[`pkgs.http-server`](https://github.com/http-party/http-server) is a simple, zero-configuration command-line static HTTP server.

this example walks through deploying one with `nix2gpu` as it is an easy to understand example of a long running process.

## // creating a [`multiService`](https://github.com/juspay/services-flake/blob/647bff2c44b42529461f60a7fe07851ff93fb600/nix/lib.nix#L1-L34) module //

`nix2gpu` uses [`services-flake`](https://github.com/juspay/services-flake)'s [`multiService`](https://github.com/juspay/services-flake/blob/647bff2c44b42529461f60a7fe07851ff93fb600/nix/lib.nix#L1-L34) module system for adding custom services.

> need an example? check out our [ComfyUI service](https://github.com/weyl-ai/nix2gpu/blob/e9929d9b739276b20b395d6d3dcac25b650c9287/services/comfyui.nix) or [`services-flake`'s internal services directory](https://github.com/juspay/services-flake/tree/8b6244f2b310f229568d5cadf7dfcb5ebe6f8bda/nix/services).

the module for `pkgs.http-server` would look something like:

### `http-server.nix`

```nix
{
  lib,
  name,
  config,
  pkgs,
  ...
}:
{
  options = {
    package = lib.mkPackageOption pkgs "http-server" { };
  };

  config.outputs.settings.processes."${name}" =
    {
      command = lib.getExe config.package;
      availability = {
        restart = "on_failure";
        max_restarts = 5;
      };
    };
}
```

next, you have to reference that service module inside your `nix2gpu` configuration:

### `server.nix`

```nix
{
  inputs,
  ...
}:
let
  inherit (inputs) nix2gpu;
in
{
  imports = [
    nix2gpu.flakeModule
  ];

  perSystem.nix2gpu.server = {
    serviceModules = [
      ./http-server.nix
    ];
    # Configure your new service module here after importing it
    services.http-server.server.enable = true;
    registries = [ "ghcr.io/weyl-ai" ];
    exposedPorts = {
      "8080/tcp" = {};
      "22/tcp" = {};
    };
  };
}
```

this is all the code you need to write. after this you can:

- Run the services only on your local machine with `nix run .#server-services`
- Build the container instance that runs your services on startup with `nix build .#server`
