# // bubblewrap mode //

run `nix2gpu` containers without docker, podman, or any container runtime. just bubblewrap + nix.

______________________________________________________________________

## // why bubblewrap //

**bubblewrap** (`bwrap`) is a lightweight sandboxing tool that uses Linux namespaces to create isolated environments. Unlike docker/podman:

- **no daemon** required
- **startup in milliseconds** instead of seconds
- **works on systems without container runtimes**
- **simpler architecture** - just a binary that execs into your process
- **no copy out of the nix store** - nix built containers must be copied out of the nix store contents into the container runtime. bubblewrap mounts the nix store directly.

Useful when you want to run GPU workloads on a host that has nix but no container infrastructure, or for iterating faster.

______________________________________________________________________

## // how it works //

`nix2gpu` leverages Nimi's built-in bubblewrap support. When you build a container with bubblewrap enabled, Nimi generates a wrapper script that:

1. **bind mounts** the nix store and container filesystem into a new namespace
1. **binds GPU devices** (`/dev/nvidia*`, `/dev/dri`) from the host
1. **sets up a minimal `/proc`** with NVIDIA driver visibility
1. **executes the startup script** in the sandboxed environment
1. **runs Nimi** to manage your services

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         host system                                     │
│  ┌──────────────┐    ┌─────────────────────────────────────────────┐    │
│  │   nix store  │────│  bubblewrap sandbox (new user namespace)    │    │
│  │  /nix/store  │    │                                             │    │
│  └──────────────┘    │  ┌──────────┐  ┌─────────┐  ┌───────────┐   │    │
│                      │  │/bin, /lib│  │/dev/nv* │  │ /proc     │   │    │
│  ┌──────────────┐    │  │(ro bind) │  │(dev bind│  │(ro bind)  │   │    │
│  │   GPU devs   │────│  └──────────┘  └─────────┘  └───────────┘   │    │
│  │  /dev/nvidia*│    │                                             │    │
│  └──────────────┘    │         Nimi + your services                │    │
│                      │                                             │    │
│  ┌──────────────┐    │  ┌─────────────────────────────────────┐    │    │
│  │ NVIDIA libs  │────│  │     nix2gpu startup.sh              │    │    │
│  │/lib/x86_64.. │    │  │  (sets up /etc, GPU libs, SSH...)   │    │    │
│  └──────────────┘    │  └─────────────────────────────────────┘    │    │
│                      └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

______________________________________________________________________

## // key differences from containers //

| aspect | container mode | bubblewrap mode |
|--------|---------------|-----------------|
| **runtime** | docker/podman | bubblewrap binary |
| **isolation** | full container | user namespace only |
| **startup time** | ~1-5 seconds | ~50-200ms |
| **image format** | OCI tarball | nix store paths directly |
| **GPU access** | `--gpus all` flag | bind mounts from host |
| **networking** | container bridge | host network (by default) |

______________________________________________________________________

## // filesystem setup //

Unlike container layers which overlay on top of each other, bubblewrap uses bind mounts. This requires different handling:

### **read-only binds**

Each subdirectory from your container's `copyToRoot` is individually bound:

```
/nix/store/xxx-base-system/bin   → /bin
/nix/store/xxx-base-system/lib   → /lib
/nix/store/xxx-base-system/usr   → /usr
```

This gives the same view as a container, but via bind mounts instead of overlayfs.

### **GPU library binds**

Host NVIDIA libraries are bound into the sandbox:

```
/lib/x86_64-linux-gnu       → /lib/x86_64-linux-gnu
/usr/lib/x86_64-linux-gnu   → /usr/lib/x86_64-linux-gnu
/usr/bin/nvidia-smi         → /usr/bin/nvidia-smi
```

### **device binds**

GPU devices from the host are made available:

```
/dev/nvidiactl
/dev/nvidia-modeset
/dev/nvidia-uvm
/dev/nvidia0 through /dev/nvidia7
/dev/dri
```

### **procfs handling**

The container gets the **host's `/proc`** instead of a private one. This is required because NVIDIA drivers expose GPU state through `/proc/driver/nvidia`, which only exists in the host's procfs.

______________________________________________________________________

## // runtime directories //

Directories that need to be mutable are set up as tmpfs mounts:

- `/tmp` - temporary files
- `/run` - runtime state
- `/var` - variable data
- `/root` - root's home directory
- `/home` - user home directories

The startup script (`startup.sh`) populates `/etc` and `/root` from the nix store on first run since these start empty in bubblewrap mode.

______________________________________________________________________

## // usage //

### **basic setup**

Bubblewrap mode is already configured through Nimi settings. No additional flake inputs needed:

```nix
perSystem.nix2gpu."my-gpu-app" = {
  # Your normal nix2gpu config
  services.myapp = {
    process.argv = [ (lib.getExe pkgs.myapp) ];
  };
};
```

### **running**

Build the bubblewrap wrapper instead of the OCI image:

```bash
# Run your `nix2gpu` instance in bubblewrap
nix run .#my-gpu-app.runInBubblewrap
```

______________________________________________________________________

## // configuration options //

`nix2gpu` automatically translates your container config to bubblewrap equivalents:

### **environment variables**

```nix
nix2gpu."my-app" = {
  env = {
    MY_VAR = "value";
    CUDA_PATH = "${pkgs.cudaPackages_12_8.cudatoolkit}";
  };
};
```

These are passed to bubblewrap's `--setenv` flags.

### **user/uid**

```nix
nix2gpu."my-app" = {
  user = "root";  # Must exist in nix2gpuUsers
};
```

The UID is resolved from `nix2gpuUsers` and passed to bubblewrap's `--uid`.

### **working directory**

```nix
nix2gpu."my-app" = {
  workingDir = "/workspace";
};
```

Translated to bubblewrap's `--chdir`.

### **custom bubblewrap flags**

You can add additional bubblewrap options through Nimi:

```nix
nix2gpu."my-app".nimiSettings.bubblewrap = {
  # Additional read-only binds
  tryRoBinds = [
    { src = "/host/data"; dest = "/data"; }
  ];

  # Additional device binds
  tryDevBinds = [
    { src = "/dev/custom"; dest = "/dev/custom"; }
  ];

  # Share a network namespace
  shareNet = true;
};
```

______________________________________________________________________

## // when to use bubblewrap //

**good for:**

- Development environments where you want fast iteration
- Systems without docker/podman (e.g., some HPC clusters)
- CI/CD pipelines where container runtimes aren't available
- Debugging - easier to inspect the sandbox from outside

**not ideal for:**

- Production multi-tenant isolation (user namespaces are weaker than containers)
- Scenarios requiring complex network setups (no built-in container networking)
- When you need to distribute the runtime to machines without nix

______________________________________________________________________

## // debugging //

Since bubblewrap doesn't hide the process in a container runtime, debugging is easier:

```bash
# Monitor from host with standard tools
ps aux | grep bwrap
```

The startup script logs everything via `gum`, so you can see exactly what initialization steps are running.

______________________________________________________________________

## // security notes //

Bubblewrap uses **user namespaces**, which provide less isolation than containers:

- **Root in the sandbox is not real root** - it's mapped to your host UID
- **Kernel attack surface** is larger than containers (no seccomp/apparmor by default)
- **Host filesystem** is still accessible outside bind mounts (though protected by permissions)

For untrusted workloads, prefer container runtimes with stronger isolation.
