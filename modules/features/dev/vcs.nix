{ ... }: {
  flake.nixosModules.vcs = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git # version control
      gh # github cli
      lazygit # git tui
    ];
  };
}
