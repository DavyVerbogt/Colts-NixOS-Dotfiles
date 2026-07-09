{ ... }: {
  flake.nixosModules.blender = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.blender ];
  };
}
