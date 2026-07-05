{ ... }: {
  flake.nixosModules.mimeDefaults = { pkgs, ... }: {
    environment.etc."xdg/mimeapps.list".text = ''
      [Default Applications]
      inode/directory=thunar.desktop
      x-scheme-handler/nxm=amethyst.desktop
      x-scheme-handler/nxm-protocol=amethyst.desktop
      x-scheme-handler/nxm=nexusmods-app.desktop
    '';
    system.activationScripts.userMimeDefaults = {
      text = ''
        ${pkgs.util-linux}/bin/runuser -u colt -- \
          ${pkgs.xdg-utils}/bin/xdg-mime default thunar.desktop inode/directory
      '';
    };
  };
}
