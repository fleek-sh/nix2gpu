{ pkgs }:
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

  tmuxConf = pkgs.writeText "tmux.conf" ''
    set  -g default-terminal "tmux-256color"
    set  -g base-index      1
    setw -g pane-base-index 1

    set -g status-keys emacs
    set -g mode-keys   emacs

    unbind C-b
    set -g prefix C-o
    bind -n C-o send-prefix

    set  -g mouse             on
    setw -g aggressive-resize on
    setw -g clock-mode-style  24
    set  -s escape-time       10
    set  -g history-limit     50000

    set -ga terminal-overrides ",xterm-256color:Tc,alacritty:RGB,wezterm:RGB,ghostty:RGB"
    set -g allow-passthrough on
    set -g focus-events on
    set -g set-titles on

    set -g status-interval 5
    set -g status-position bottom
    set -g status-style "fg=#4d9fff,bg=#13161a"
    set -g status-left ""
    set -g status-right " #[fg=#4d9fff]%H:%M #h #(whoami) "
    set -g status-right-length 100

    set -g window-status-separator ""
    set -g window-status-current-format " #[fg=#d8e0e7,bold]#W "
    set -g window-status-format " #[fg=#666666]#W "

    set -g pane-border-lines heavy
    set -g pane-active-border-style "fg=#4d9fff"
    set -g pane-border-style "fg=#23292f"

    bind | split-window -h -c "#{pane_current_path}"
    bind - split-window -v -c "#{pane_current_path}"
    bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
    bind-key n next-window
    bind-key p previous-window
    bind-key C-o last-window
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

  startupScript = pkgs.writeScript "startup.sh" (builtins.readFile ./startup.sh);
}
