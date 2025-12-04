# // architecture overview //

how `nix2gpu` works under the hood.

______________________________________________________________________

## // the big picture //

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   nix flake     │────│  nix2container  │────│   OCI image     │
│   definition    │    │   build system  │    │   (layered)     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ container config│    │  startup script │    │ docker/podman   │
│   (nix modules) │    │ + process graph │    │    runtime      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**nix2gpu** transforms declarative nix configurations into reproducible GPU containers through a multi-stage build process.

______________________________________________________________________

## // build pipeline //

### 1. **nix evaluation**

```nix
perSystem.nix2gpu."my-container" = {
  cudaPackages = pkgs.cudaPackages_12_8;
  tailscale.enable = true;
  services.nginx."web" = { enable = true; };
};
```

The nix module system processes your configuration, applying defaults, validating options, and computing the final container specification.

### 2. **dependency resolution**

```bash
nix build .#my-container
```

Nix builds the entire dependency graph:

- Base system packages (bash, coreutils, etc.)
- CUDA toolkit and drivers
- Your application packages
- Service configurations
- Startup scripts

### 3. **image assembly**

```nix
nix2container.buildImage {
  name = "my-container";
  copyToRoot = [ baseSystem cudaPackages userPackages ];
  config.Entrypoint = [ "/nix/store/.../startup.sh" ];
}
```

`nix2container` creates an OCI image with:

- Layered filesystem for efficient caching
- Only necessary dependencies included
- Reproducible layer ordering

### 4. **container execution**

```bash
docker run --gpus all my-container:latest
```

The startup script orchestrates initialization, then process-compose manages services.

______________________________________________________________________

## // filesystem layout //

```
/
├── nix/
│   └── store/          # immutable package store
│       ├── cuda-*      # CUDA toolkit
│       ├── startup-*   # initialization script  
│       └── packages-*  # your applications
├── etc/
│   ├── ssh/            # SSH daemon config
│   └── ld.so.conf.d/   # library search paths
├── run/
│   └── secrets/        # mounted secret files
├── workspace/          # default working directory
└── tmp/                # temporary files
```

**Key principles:**

- **Immutable system**: `/nix/store` contains all software, never modified at runtime
- **Mutable state**: `/workspace`, `/tmp`, `/run` for runtime data
- **Secrets**: mounted at `/run/secrets` from external sources
- **Library paths**: dynamic loader configured for both nix store and host-mounted drivers

______________________________________________________________________

## // startup sequence //

The container initialization follows a precise sequence:

### 1. **environment setup**

```bash
# startup.sh
export PATH="/nix/store/.../bin:$PATH"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/lib/x86_64-linux-gnu"
export CUDA_PATH="/nix/store/...-cuda-toolkit"
```

- Sets up PATH for nix store binaries
- Configures library search for both nix store and host-mounted NVIDIA drivers
- Establishes CUDA environment

### 2. **runtime detection**

```bash
if [[ -d "/lib/x86_64-linux-gnu" ]]; then
  echo "vast.ai runtime detected"
  # patch nvidia utilities for host drivers
elif [[ -n "$RUNPOD_POD_ID" ]]; then
  echo "runpod runtime detected"  
  # configure network volumes
else
  echo "bare-metal/docker runtime detected"
fi
```

Adapts configuration based on detected cloud provider or bare-metal environment.

### 3. **GPU initialization**

```bash
# link host drivers to expected locations
ldconfig

# test GPU access
nvidia-smi || echo "GPU not available"
```

Ensures GPU toolchain works with both nix store CUDA and host-mounted drivers.

### 4. **network setup**

```bash
# tailscale daemon (if enabled)
if [[ -n "$TAILSCALE_AUTHKEY_FILE" ]]; then
  tailscaled --state-dir=/tmp/tailscale &
  tailscale up --authkey="$(cat $TAILSCALE_AUTHKEY_FILE)"
fi

# SSH daemon
mkdir -p /var/empty /var/log
sshd
```

Starts networking services: Tailscale for mesh networking, SSH for remote access.

### 5. **service orchestration**

```bash
# if services defined: start process-compose
if [[ -f "/nix/store/.../process-compose.yaml" ]]; then
  exec process-compose up
else
  # interactive shell
  exec bash
fi
```

Either launches your defined services or drops to an interactive shell.

______________________________________________________________________

## // service management //

### **process-compose**

`nix2gpu` uses [process-compose](https://github.com/F1bonacc1/process-compose) instead of systemd for service management:

```yaml
# generated from your services config
processes:
  nginx:
    command: nginx -g 'daemon off;'
    restart_policy:
      restart: always
      max_restarts: 5
    availability:
      restart: exit_on_failure
    depends_on:
      postgres:
        condition: process_started
  postgres:
    command: postgres -D /workspace/db
    restart_policy:
      restart: always
```

**Benefits over systemd:**

- No init system complexity
- Better Docker integration
- Dependency management
- JSON/YAML configuration
- Built-in health checks

### **service lifecycle**

1. **Dependency resolution**: services start in correct order
1. **Health monitoring**: automatic restart on failure
1. **Log aggregation**: all service logs to stdout for `docker logs`
1. **Graceful shutdown**: proper signal handling for container stops

______________________________________________________________________

## // networking architecture //

### **standard mode** (docker/podman)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    host     │────│  container  │────│   service   │
│ localhost:* │    │   bridge    │    │ localhost:* │
└─────────────┘    └─────────────┘    └─────────────┘
```

Standard container networking with port forwarding.

### **tailscale mode** (mesh networking)

```
┌─────────────┐    ┌─────────────────┐    ┌─────────────┐
│   host-a    │    │   tailscale     │    │   host-b    │
│ container-a ├────┤  mesh network   ├────┤ container-b │
│10.0.0.100:22│    │                 │    │10.0.0.101:22│
└─────────────┘    └─────────────────┘    └─────────────┘
```

Direct container-to-container communication across hosts via Tailscale.

**Key advantages:**

- No port forwarding needed
- Works across clouds and networks
- End-to-end encryption
- DNS-based service discovery
- ACL-based access control

______________________________________________________________________

## // GPU integration //

### **driver compatibility**

```bash
# nix store CUDA toolkit
/nix/store/...-cuda-toolkit/
├── bin/nvcc
├── lib/libcuda.so       # stub library
└── include/cuda.h

# host-mounted real drivers  
/lib/x86_64-linux-gnu/
├── libcuda.so.1         # actual GPU driver
├── libnvidia-ml.so.1
└── libnvidia-encode.so.1
```

**The challenge**: CUDA applications need both:

- CUDA toolkit (development headers, nvcc compiler) from nix store
- Actual GPU drivers from the host system

**The solution**: dynamic library path configuration

```bash
export LD_LIBRARY_PATH="/nix/store/...-cuda/lib:${LD_LIBRARY_PATH}:/lib/x86_64-linux-gnu"
ldconfig
```

This allows nix store CUDA to find host-mounted drivers at runtime.

### **cloud provider adaptations**

**vast.ai**: NVIDIA drivers mounted at `/lib/x86_64-linux-gnu`

```bash
# startup.sh detects vast.ai and configures paths
patchelf --set-rpath /lib/x86_64-linux-gnu /nix/store/.../nvidia-smi
```

**runpod**: Standard nvidia-docker integration

```bash
# uses nvidia-container-toolkit mounts
# drivers available via standard paths
```

**bare-metal**: Host nvidia-docker setup

```bash
# relies on proper nvidia-container-toolkit configuration
# GPU access via device mounts: --gpus all
```

______________________________________________________________________

## // secret management //

### **security principles**

1. **Secrets never enter nix store** (nix store is world-readable)
1. **Runtime-only access** (secrets mounted at container start)
1. **File-based injection** (not environment variables)
1. **Minimal exposure** (secrets only accessible to specific processes)

### **agenix integration**

```nix
nix2gpu."my-container" = {
  age.secrets.tailscale-key = {
    file = ./secrets/ts-key.age;
    path = "/run/secrets/ts-key";
  };

  tailscale.authKeyFile = config.secrets.tailscale-auth.path;
};
```

**Flow:**

1. Host system decrypts secrets to `/run/secrets/`
1. Container mounts `/run/secrets` as volume
1. Container references secrets by path, never by value

______________________________________________________________________

## // caching & performance //

### **layer optimization**

```nix
# nix2container creates efficient layers
[
  layer-01-base-system     # coreutils, bash, etc.
  layer-02-cuda-toolkit    # large but stable
  layer-03-python-packages # frequently changing  
  layer-04-app-code        # most frequently changing
]
```

Frequently changing components go in higher layers to maximize cache hits.

### **build caching**

```bash
# first build: downloads everything
nix build .#my-container  # ~15 minutes

# subsequent builds: only changed layers
nix build .#my-container  # ~30 seconds
```

Nix's content-addressed store ensures perfect reproducibility with efficient incremental builds.

### **registry layer sharing**

```bash
# multiple containers share base layers
my-container:v1    # 2GB total (8 layers)
my-container:v2    # +100MB (only top layer changed)
other-container:v1 # +500MB (shares 6 bottom layers)
```

OCI registries deduplicate shared layers across images.

______________________________________________________________________

## // extending the system //

### **custom services**

```nix
# services/my-service.nix
{ lib, pkgs, ... }:
let inherit (lib) mkOption types; in
{
  options.services.my-service = mkOption {
    type = types.submodule {
      options = {
        enable = mkOption { type = types.bool; default = false; };
        port = mkOption { type = types.int; default = 8080; };
        # ... other options
      };
    };
  };
  
  config = lib.mkIf config.services.my-service.enable {
    # generate process-compose configuration
  };
}
```

### **custom cloud targets**

```nix
# modules/container/scripts/copy-to-my-cloud.nix
{
  perSystem = { pkgs, self', ... }: {
    perContainer = { container, ... }: {
      scripts.copy-to-my-cloud = pkgs.writeShellApplication {
        name = "copy-to-my-cloud";
        text = ''
          # implement your cloud's container registry push
        '';
      };
    };
  };
}
```

The modular architecture makes it straightforward to add new cloud providers or service types.
