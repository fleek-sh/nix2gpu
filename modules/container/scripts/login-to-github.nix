{
  perSystem =
    { pkgs, ... }:
    {
      packages.loginToGithub = pkgs.writeShellApplication {
        name = "login-to-github-registry";
        runtimeInputs = with pkgs; [
          gh
          skopeo
        ];
        text = ''
          if ! gh auth status &>/dev/null; then
            echo "authenticating with github..."
            gh auth login --scopes write:packages
          fi

          GH_TOKEN=$(gh auth token)
          GH_USER=$(gh api user --jq .login)

          echo "$GH_TOKEN" | skopeo login ghcr.io -u "$GH_USER" --password-stdin
          echo "successfully logged into ghcr.io!"
        '';
      };
    };
}
