{ self, ... }: {
  flake.nixosModules.niridesktop = { pkgs, ... }: {
    imports = [
      self.nixosModules.archive
      self.nixosModules.clipboard
      self.nixosModules.cursor
      self.nixosModules.gtkSettings
      self.nixosModules.gtkTheme
      self.nixosModules.iconTheme
      self.nixosModules.kitty
      self.nixosModules.media
      self.nixosModules.niri
      self.nixosModules.screenshot
      self.nixosModules.thunar
    ];
  };
}
