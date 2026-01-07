# // services & runtime //

managing long-running processes inside `nix2gpu` containers.

______________________________________________________________________

## // overview //

`nix2gpu` uses [`Nimi`](https://github.com/weyl-ai/nimi), a tiny process manager
for [NixOS modular services](https://nixos.org/manual/nixos/unstable/#modular-services)
(Nix 25.11). Define services under `services.<name>` and `nix2gpu` will build an
OCI image with Nimi as the entrypoint.

No extra flake inputs are required to enable services.

______________________________________________________________________

## // defining services //

### **using existing modular services**

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

### **a minimal custom service**

```nix
services."hello" = {
  process.argv = [
    (lib.getExe pkgs.bash)
    "-lc"
    "echo hello from Nimi"
  ];
};
```

For a full custom module example, see [defining custom services](custom-service.md).

______________________________________________________________________

## // runtime behavior //

When the container starts, Nimi runs the `nix2gpu` startup hook and then launches
all configured services. You can still drop into a shell for debugging with:

```bash
$ docker run -it --entrypoint bash my-container:latest
```

______________________________________________________________________

## // restart policies //

`Nimi` controls service restarts. Tune it with `nimiSettings.restart`:

```nix
nimiSettings.restart = {
  mode = "up-to-count"; # never | up-to-count | always
  time = 2000;           # delay in ms
  count = 3;             # max restarts when using up-to-count
};
```

______________________________________________________________________

## // logging //

Logs always stream to stdout/stderr for `docker logs`. You can also enable
per-service log files:

```nix
nimiSettings.logging = {
  enable = true;
  logsDir = "nimi_logs";
};
```

At runtime, Nimi creates a `logs-<n>` directory under `logsDir` and writes one
file per service.

______________________________________________________________________

## // config data //

Modular services can provide config files via `configData`. Nimi exposes these
files under a temporary directory and sets `XDG_CONFIG_HOME` for the service.
This lets services read configs from `$XDG_CONFIG_HOME/<path>` without writing to
the Nix store.

See `nix2gpu` service modules like `services/comfyui.nix` for real-world usage.
