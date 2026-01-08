{ pkgs, ... }:
{
  programs.bash = {
    enable = true;
    bashrcExtra = builtins.readFile ./.bashrc;
  };

  programs.atuin = {
    enable = true;
    enableBashIntegration = true;
  };

  home.packages = with pkgs; [
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
