{ ... }: {
  # Confirmed a real, currently-maintained nixpkgs package
  # (pkgs/by-name/bl/blockbench/package.nix, present in nixos-unstable and
  # recent stable channels) — split into its own file rather than bundled
  # into blender.nix, matching the one-program-per-file convention the rest
  # of features/ already follows (kitty.nix, zen.nix, spicetify.nix, etc.).
  flake.nixosModules.blockbench = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.blockbench ];
  };
}
