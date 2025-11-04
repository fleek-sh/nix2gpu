{ pkgs, self }:
let
  inherit (pkgs) lib;

  inherit (import ../packages/environment.nix { inherit pkgs lib; }) corePkgs networkPkgs;
in
{
  nixConfContents = ''
    sandbox = false
    build-users-group =
    experimental-features = nix-command flakes
    trusted-users = root
    max-jobs = auto
    cores = 0
    trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=
    substituters = https://cache.nixos.org https://nix-community.cachix.org https://cuda-maintainers.cachix.org https://cache.garnix.io
    keep-outputs = true
    keep-derivations = true
    accept-flake-config = true
  '';

  sshdConfig = pkgs.writeText "sshd_config" ''
    Port 22
    PermitRootLogin yes
    PasswordAuthentication yes
    PubkeyAuthentication yes
    PermitEmptyPasswords yes
    ChallengeResponseAuthentication no
    UsePAM no
    PrintMotd no
    X11Forwarding no
    AcceptEnv LANG LC_*
    Subsystem sftp ${pkgs.openssh}/libexec/sftp-server
    PidFile /run/sshd.pid
    HostKey /etc/ssh/ssh_host_rsa_key
    HostKey /etc/ssh/ssh_host_ecdsa_key
    HostKey /etc/ssh/ssh_host_ed25519_key
  '';

  startupScript = pkgs.writeShellApplication {
    name = "startup.sh";
    text = builtins.readFile ./startup.sh;

    runtimeInputs = corePkgs ++ networkPkgs ++ [ self.homeConfigurations.default.activationPackage ];
  };
}
