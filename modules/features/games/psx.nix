{ ... }:
{
  flake.nixosModules.psx = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.pcsx2-bin
    ];
  };
}
