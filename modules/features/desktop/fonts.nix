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
  flake.nixosModules.mimeDefaults = { pkgs, ... }: {
    environment.etc."xdg/mimeapps.list".text = ''
      [Default Applications]
      inode/directory=thunar.desktop
      x-scheme-handler/nxm=amethyst.desktop
      x-scheme-handler/nxm-protocol=amethyst.desktop
      x-scheme-handler/nxm=nexusmods-app.desktop
    '';

    # Steam's browse-local-files action runs xdg-open inside a steam-run /
    # pressure-vessel sandbox, which does NOT reliably see /etc/xdg — only
    # real $HOME is bind-mounted in there. Without a matching user-level
    # override, xdg-open falls through to the merged mimeinfo.cache and
    # picks up kitty's own generic inode/directory handler (kitty-open.desktop,
    # "kitty +open %U"), which errors on bare directories ("No directories to
    # watch provided") and just sits there as a blank terminal. Enforcing the
    # same default in ~/.config/mimeapps.list on every activation keeps this
    # working regardless of what the sandbox can see.
    system.activationScripts.userMimeDefaults = {
      text = ''
        ${pkgs.util-linux}/bin/runuser -u colt -- \
          ${pkgs.xdg-utils}/bin/xdg-mime default thunar.desktop inode/directory
      '';
    };
  };
}
