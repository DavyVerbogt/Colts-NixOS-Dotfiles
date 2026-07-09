{ ... }:
{
  flake.nixosModules.psx = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      pcsx2
      mymcplus
    ];
  };
}
