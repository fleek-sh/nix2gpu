{ lib, ... }:
{
  options.bubblewrapTmpfsDirs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    description = ''
      Directories that should be tmpfs (not bind mounted from copyToRootEnv)
    '';
    default = [
      "tmp"
      "run"
      "var"
      "etc"
      "root"
      "home"
      "proc"
      "dev"
      "nix"
      "sys"
    ];
    internal = true;
  };

  config.nimiSettings.bubblewrap = {
    extraTmpfs = [
      "/tmp"
      "/run"
      "/var"
      "/root"
      "/home"
      "/etc/ssh"
      "/etc/ld.so.conf.d"
    ];

    environment = {
      NIX_REMOTE = "daemon";
      NIX2GPU_BUBBLEWRAP_MODE = "1";
    };

    # Use host's /proc for GPU driver access
    # NVIDIA driver requires /proc/driver/nvidia which only exists in host's procfs
    bind.proc = false;
    prependFlags = [
      "--ro-bind"
      "/proc"
      "/proc"
    ];

    tryDevBinds = lib.mkAfter [
      {
        src = "/dev/net/tun";
        dest = "/dev/net/tun";
      }
      {
        src = "/nix/var/nix/daemon-socket";
        dest = "/nix/var/nix/daemon-socket";
      }
    ];
  };

}
