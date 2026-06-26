{ ... }: {
  flake.nixosModules.editor = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim # editor
      nil # nix language server
      nixfmt # nix formatter
      claude-code
    ];
  };
}
