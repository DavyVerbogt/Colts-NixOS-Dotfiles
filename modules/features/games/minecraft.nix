{ ... }: {
  flake.nixosModules.minecraft = { pkgs, lib, ... }: {
    environment.systemPackages = [
      # symlinkJoin (not runCommand + makeWrapper) so the FULL package tree
      # comes along — share/applications/*.desktop and share/icons included.
      # The old runCommand output contained only bin/prismlauncher, which is
      # why the launcher entry disappeared: no .desktop file was installed
      # anywhere. wrapProgram then replaces just the bin symlink with the
      # env-fixing wrapper; the desktop file's `Exec=prismlauncher` resolves
      # via PATH, so launcher-started instances get the same fixes.
      # Same idiom as media/vesktop.nix and dev/vscodium.nix.
      (pkgs.symlinkJoin {
        name = "prismlauncher-wrapped";
        paths = [ pkgs.prismlauncher ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/prismlauncher \
            --unset WAYLAND_DISPLAY \
            --set __GL_THREADED_OPTIMIZATIONS 0
        '';
      })
    ];
  };
}
