# // defining a custom service //

Use NixOS modular services (Nix 25.11) to describe long-running processes.
`nix2gpu` runs them through `Nimi`, so there is no extra flake input to enable.

______________________________________________________________________

# // example: a simple HTTP server //

This example defines a tiny service module that runs `python -m http.server`.

### `simple-http.nix`

```nix
{ lib, pkgs, ... }:
{ config, ... }:
let
  inherit (lib) mkOption types;
  cfg = config.simpleHttp;
in
{
  _class = "service";

  options.simpleHttp = {
    port = mkOption {
      type = types.port;
      default = 8080;
    };
    bind = mkOption {
      type = types.str;
      default = "0.0.0.0";
    };
    directory = mkOption {
      type = types.str;
      default = "/workspace";
    };
  };

  config.process.argv = [
    (lib.getExe pkgs.python3)
    "-m"
    "http.server"
    "--bind"
    cfg.bind
    "--directory"
    cfg.directory
    (toString cfg.port)
  ];
}
```

### `server.nix`

```nix
{ lib, ... }:
{
  perSystem = { pkgs, ... }: {
    nix2gpu."simple-http" = {
      services."web" = {
        imports = [ (lib.modules.importApply ./simple-http.nix { inherit pkgs; }) ];
        simpleHttp = {
          port = 8080;
          directory = "/workspace/public";
        };
      };

      exposedPorts = {
        "8080/tcp" = {};
        "22/tcp" = {};
      };
    };
  };
}
```

______________________________________________________________________

# // using existing modular services //

If a package ships a modular service module, you can import it directly. For
example, `ghostunnel` from `nixpkgs`:

```nix
services."ghostunnel" = {
  imports = [ pkgs.ghostunnel.services ];
  ghostunnel = {
    listen = "0.0.0.0:443";
    cert = "/root/service-cert.pem";
    key = "/root/service-key.pem";
    disableAuthentication = true;
    target = "backend:80";
    unsafeTarget = true;
  };
};
```

Need a fuller reference? See `services/comfyui.nix` for a real-world service
module.
