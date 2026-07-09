{ ... }: {
  # Opt-in — NOT added to ws01-nixConfig's imports by default. Add
  # `virtualization` to that imports list yourself if/when you want it
  # (Windows VM for something Proton can't run, or an isolated sandbox for
  # testing untrusted mods before installing them system-wide via Amethyst).
  flake.nixosModules.virtualization = { pkgs, ... }: {
    virtualisation.libvirtd.enable = true;
    environment.systemPackages = [ pkgs.virt-manager ];
    users.users.colt.extraGroups = [ "libvirtd" ];
  };
}
