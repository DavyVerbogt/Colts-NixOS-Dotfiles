{ self, inputs, ... }: {
  flake.nixosModules.dev = { pkgs, ... }: {
    imports = [
      self.nixosModules.direnv
      self.nixosModules.fetch
      self.nixosModules.editor
      self.nixosModules.vcs
      self.nixosModules.vscodium
      self.nixosModules.claude
      self.nixosModules.shell
      self.nixosModules.matugen
    ];
  };
}
