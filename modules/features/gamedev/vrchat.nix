{ ... }: {
  # VRChat's own Creator Companion doesn't ship a working Linux GUI — only
  # Windows is officially supported, with limited CLI-only behavior
  # elsewhere. ALCOM (built on vrc-get) is the community open-source
  # replacement and IS packaged in nixpkgs (uses the same settings file as
  # VCC, so nothing to migrate). As of nixpkgs 25.05 it has a known native
  # Wayland rendering bug — opens blank or crashes (nixos/nixpkgs#435243);
  # forcing XWayland via GDK_BACKEND=x11 is the documented workaround,
  # wrapped the same way games/minecraft.nix already wraps prismlauncher
  # with makeWrapper for its own Wayland-related env fix.
  flake.nixosModules.vrcc = { pkgs, lib, ... }: {
    environment.systemPackages = [
      (pkgs.runCommand "alcom-wrapped"
        { nativeBuildInputs = [ pkgs.makeWrapper ]; }
        ''
          mkdir -p $out/bin
          makeWrapper ${lib.getExe pkgs.alcom} $out/bin/alcom \
            --set GDK_BACKEND x11
        ''
      )
      pkgs.vrc-get # CLI client — useful for scripted project setup
    ];
  };
}
