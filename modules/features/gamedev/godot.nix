{ ... }: {
  # Verify the exact attribute name against your nixpkgs pin — it's shifted
  # between godot / godot_4 / godot4-mono historically as the 3.x->4.x
  # transition happened.
  flake.nixosModules.godot = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.godot_4 ];
  };
}
