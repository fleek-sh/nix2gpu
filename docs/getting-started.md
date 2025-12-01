# // `ComfyUI` setup guide //

This guide covers a walk through of setting up `ComfyUI` inside a `nix2gpu` container, and then deploying it to `vast.ai`. It should hopefully also provide useful information to others trying to deploy different pieces of software too.

# Installing Nix

First of all, you'll need to install [Nix](https://nixos.org/).

There are a couple of easy ways to get it:

- The [Determinate Nix Installer](https://github.com/DeterminateSystems/nix-installer) (Mac, Linux)

- [NixOS WSL](https://github.com/nix-community/NixOS-WSL) (Windows subsystem for Linux)

# Creating a flake to develop out of:

With nix installed you can now run:

```sh
mkdir my-nix2gpu-project

cd my-nix2gpu-project

git init

nix flake init

git add .

git commit -m "nix flake init"
```

# Adding Inputs

You will now have a new git repository with an empty `flake.nix`. Edit this to add

```nix
nix2gpu.url = "github:weyl-ai/nix2gpu?ref=baileylu/public-api";

systems.url = "github:nix-systems/default";

flake-parts.url = "github:hercules-ci/flake-parts";
```

Into the `inputs` section.

# Replace the outputs section with this:

```nix
outputs =
  inputs@{ flake-parts, self, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      inputs.nix2gpu.flakeModule
    ];

    systems = import inputs.systems;

    # This is where nix2gpu config goes
    # More on this later
    perSystem.nix2gpu = {};
  };
```

# Select a `nix2gpu` starter config to use

Take a look in the [examples folder](https://github.com/weyl-ai/nix2gpu/tree/baileylu/public-api/examples) and pick one which looks useful.

Going forward, we will use the `comfyui.nix` example.

We can run this in `nix2gpu` like (replacing the `perSystem.nix2gpu` from earlier:

```nix
{
  perSystem = { pkgs, ... }: {
    nix2gpu."comfyui-service" = {
      services.comfyui."comfyui-example" = {
        enable = true;
        # You'll need to use the nixified-ai overlay for this
        # Check them out - https://github.com/nixified-ai/flake
        models = [ pkgs.nixified-ai.models.stable-diffusion-v1-5 ];
      };

      registries = [ "ghcr.io/weyl-ai" ];

      exposedPorts = {
        "22/tcp" = { };
        "8188/tcp" = { };
        "8188/udp" = { };
      };
    };
  };
}

```

# Getting the `ComfyUI` instance onto vast

You can now build and copy your service to the GitHub package registry (ghcr.io) with

```sh
nix run .#comfyui-service.copyToGithub
```

Next, go to the vast.ai web UI and create a new template, using the GitHub package we just pushed as the source when prompted.

Now, reserve a new instance on vast using the template and give it a few minutes to start up (wait for "Running...").

Now, use the web UI to add an ssh key. You can get/find your public key [with this guide](https://www.digitalocean.com/community/tutorials/how-to-configure-ssh-key-based-authentication-on-a-linux-server). Once you have it, use the key shaped button on your running vast instance and paste the key starting with `ssh-rsa` or `ssh-ed` into the keys for the instance.

You can now connect with the command and IP address it gives you. Make sure you use `-L 8188: localhost:8188` to be able to view comfy UI in your browser.

# Other options

You can also run a `nix2gpu` image locally if you have docker or `podman` installed:

```nix
nix run .#my-service.copyToDockerDaemon
nix run .#shell
```
