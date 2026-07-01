{ ... }: {
  flake.nixosModules.amm = { pkgs, ... }: {
    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
