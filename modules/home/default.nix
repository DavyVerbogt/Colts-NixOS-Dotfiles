{ self, inputs, lib, ... }: {

  # flake.nixosModules gets automatic multi-file merging for free — that's
  # built into flake-parts core. flake.homeManagerModules is NOT a
  # recognized flake output, so without this declaration, every file that
  # does `flake.homeManagerModules.<name> = ...` (fish.nix, git.nix,
  # kitty.nix, gtk.nix, cursor.nix) is treated as a competing single
  # definition of the whole `flake.homeManagerModules` attribute instead of
  # a contribution to it — "defined multiple times, no option declared to
  # merge them" is exactly that. lazyAttrsOf deferredModule matches
  # flake-parts' own real declaration for nixosModules, since the values
  # stored here are the same shape: raw, not-yet-evaluated module functions.
  options.flake.homeManagerModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules exposed by this flake, keyed by name.";
  };

  config.flake.nixosModules.homeManagerBase = { pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-bak";
      users.colt.imports = with self.homeManagerModules; [
        fish
        git
        kitty
        gtk
        cursor
      ];
    };
  };
}
