{ ... }: {

  # Sole owner of /etc/xdg/mimeapps.list. Previously split across
  # games/modmanager.nix and games/steam.nix, each writing their own
  # [Default Applications] block — environment.etc.<name>.text is
  # types.lines, which silently *concatenates* multiple definitions instead
  # of erroring, so the two blocks landed in the same file as two separate
  # [Default Applications] sections. desktop-file-utils' ini parser doesn't
  # reliably merge repeated section headers, and neither block ever set
  # inode/directory (the file-manager association), which is why Steam's
  # "Browse local files" wasn't opening Thunar. Consolidated into one clean
  # section here instead.
  flake.nixosModules.mimeDefaults = { ... }: {
    environment.etc."xdg/mimeapps.list".text = ''
      [Default Applications]
      inode/directory=thunar.desktop
      x-scheme-handler/nxm=amethyst.desktop
      x-scheme-handler/nxm-protocol=amethyst.desktop
      x-scheme-handler/nxm=nexusmods-app.desktop
    '';
  };
}
