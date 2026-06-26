{ self, ... }: {
  flake.nixosModules.niridesktop = { pkgs, ... }: {
    imports = [
      self.nixosModules.clipboard
      self.nixosModules.gtk
      self.nixosModules.kitty
      self.nixosModules.media
      self.nixosModules.niri
      self.nixosModules.screenshot
      self.nixosModules.thunar
    ];
  };
}
