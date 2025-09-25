{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    bashrcExtra = builtins.readFile ./.bashrc;
  };

  home.packages = with pkgs; [
    atuin
    bat
    btop
    direnv
    eza
    fd
    file
    fzf
    htop
    jq
    lsof
    ltrace
    nix-direnv
    ripgrep
    starship
    strace
    tmux
    tree
    yq
    zoxide
  ];
}
