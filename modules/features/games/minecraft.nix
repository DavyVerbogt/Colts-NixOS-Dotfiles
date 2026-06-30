{ ... }: {
  flake.nixosModules.minecraft = { pkgs, lib, ... }: {
    environment.systemPackages = [
      (pkgs.runCommand "prismlauncher-wrapped"
        {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
        ''
          makeWrapper ${pkgs.prismlauncher}/bin/prismlauncher $out/bin/prismlauncher \
            --unset WAYLAND_DISPLAY \
            --set __GL_THREADED_OPTIMIZATIONS 0
        ''
      )
    ];
  };
}
