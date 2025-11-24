# `// nix2vast //`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

`nixos` containers for cost-effective and capable gpu compute. [vast.ai](https://vast.ai) is the first target, there will be many more.

## // init // what this is

a nix-based container runtime that makes distributed gpu compute actually work. reproducible environments, tailscale networking, `CUDA` 12.8. everything you need to turn random gpus into a coherent compute cluster.

`vast.ai` is just the beginning. any gpu, anywhere, real init system, same environment.

## // tree // architecture

```
├── checks       # flake checks run on this repo
├── config       # avalible `nix2vast` config options
├── dev          # `flake-parts` config for development of this repo
├── examples     # working `nix2vast` examples
├── services     # extra `services-flake` compatible services
└── modules      # implementation of `nix2vast`
```

clean separation of concerns. the flake stays minimal, modules do the work.

## // quick // start

create a `nix2vast` container:

```nix
perSystem.nix2vast.sample = { };
```

```bash
# build
nix build .#sample

# push to registry
nix run .#sample.copyToGIthub

# run locally (docker or podman)
nix run .#sample.copyToContainerRuntime
nix run .#sample.shell
```

## // manifest // what's inside

- **`cuda 12.8`** with `cudnn`, `nccl`, `cublas` - the whole show
- **`tailscale`** for seamless and secure networking across a heterogeneous fleet
- **`development tools`** - `gcc`, `python`, `uv`, `patchelf`
- **`modern shell`** - `tmux`, `starship`, `atuin`, `ripgrep`, `fzf`, the usual suspects
- **`nix`** - because `docker`/`OCI` is a reasonable deployment target but an unreasonable build system

## // deployment

push to `ghcr.io`, point `vast.ai` at it:

```
ghcr.io/fleek-platform/nix2vast:20250914-142437
```

or run your own registry. we don't care.

## // configuration

```bash
# optional
ROOT_PASSWORD=...
SSH_PUBLIC_KEYS=...
TAILSCALE_AUTHKEY=...
```

passwordless root by default. we're already inside the machine.

## // technical details

`vast.ai` uses debian library paths (`/lib/x86_64-linux-gnu`). their `nvidia-container-runtime` injects driver libraries at container start. we handle this gracefully:

- wait for library injection
- patch `nvidia-smi` with nix interpreter
- regenerate ldconfig cache
- seamless thereafter

it just works. deterministically.

## // development

```bash
nix develop      # enter shell
nix build        # build image
nix run .#<app>  # run apps
```

## // philosophy

cloud vendors want you to think gpu compute is complicated. it's not. it's just linux with extra libraries.

this project is an existence proof that complexity is optional.

## // contributing

send patches. fix things. make it better.

the code is `MIT`. use it however you want.

## // notes // support

built at [fleek](https://fleek.xyz). some testing in production. works on our machines, will expect it will work on yours. if not, we'll fix it.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
