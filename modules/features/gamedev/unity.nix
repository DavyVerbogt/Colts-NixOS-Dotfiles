{ ... }: {
  # Unity Hub is packaged directly in nixpkgs as a self-contained derivation
  # (pkgs.unityhub) — no need to hand-roll a buildFHSEnv for it.
  flake.nixosModules.unity = { pkgs, ... }: {
    environment.systemPackages = [
      (pkgs.unityhub.override {
        # Covers a known "Windows Build Support (Mono)" module install
        # failure (missing 7z) reported against recent unityhub builds.
        extraLibs = pkgs: [ pkgs.openssl_1_1 ];
      })
    ];
    # Unity Hub's sign-in flow shells out to xdg-open for the browser step;
    # without this it can silently fail. desktop/gtk-settings.nix already
    # enables xdg.portal — this opts into the newer portal-based xdg-open.
    xdg.portal.xdgOpenUsePortal = true;
  };
}
