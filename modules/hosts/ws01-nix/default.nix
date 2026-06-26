{ self, inputs, ... }: {

  flake.nixosConfigurations.ws01-nix = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.ws01-nixConfig
    ];
  };
}
