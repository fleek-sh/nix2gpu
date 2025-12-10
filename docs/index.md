# // index //

declarative GPU containers. vast.ai. runpod. bare-metal. zero dockerfile cope.

______________________________________________________________________

## // start here //

- **[getting started](getting-started.md)** — build your first container, ssh in
- **[options reference](options.md)** — all the knobs
- **[architecture](architecture.md)** — how it works internally
- **[services & runtime](services.md)** — process-compose, startup sequence
- **[defining custom services](custom-service.md)** — add your own service
  modules
- **[secrets & agenix](secrets.md)** — keys never touch the nix store
- **[integrations](integrations.md)** — integrations with the nix ecosystem

______________________________________________________________________

## // high-level //

1. declare containers under `perSystem.nix2gpu.<n>`
1. each container config is a nix module (like nixos modules)
1. `nix2gpu` assembles:
   - root filesystem with nix store + your packages
   - startup script for runtime environment
   - service graph via process-compose
1. helper commands:
   - `nix build .#<n>` — build image
   - `nix run .#<n>.copy-to-container-runtime` — load into docker/podman
   - `nix run .#<n>.copy-to-github` — push to ghcr
   - `nix run .#<n>.copy-to-runpod` — push to runpod

______________________________________________________________________

## // cloud targets //

| platform | status | notes |
|----------|--------|-------|
| vast.ai | ✅ stable | nvidia libs at `/lib/x86_64-linux-gnu` |
| runpod | ✅ stable | network volumes, template support |
| lambda labs | ✅ works | standard docker |
| bare-metal | ✅ works | just run the container |
| kubernetes | 🚧 wip | gpu operator integration |

______________________________________________________________________

## // where to go //

- **just want something running** → [getting started](getting-started.md)
- **want all the options** → [options reference](options.md)
- **hacking on internals** → [architecture](architecture.md)
- **secrets and tailscale** → [secrets](secrets.md)
