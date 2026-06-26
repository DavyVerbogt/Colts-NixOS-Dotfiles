{ ... }: {
  flake.nixosModules.direnv = { ... }: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true; # fast, cached `use flake` / `use nix`
    };
  };
}
