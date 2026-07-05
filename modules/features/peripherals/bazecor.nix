{ ... }: {
  flake.nixosModules.bazecor = {
    programs.bazecor.enable = true;
  };
}
