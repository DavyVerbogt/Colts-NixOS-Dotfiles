{ ... }: {
  # eza --icons, starship's prompt glyphs, and several Noctalia UI icons all
  # assume a Nerd Font is installed. Kept as its own file rather than folded
  # into fonts.nix so it doesn't collide with whatever you've already fixed
  # there.
  flake.nixosModules.nerdFont = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.nerd-fonts.jetbrains-mono ];
  };
}
