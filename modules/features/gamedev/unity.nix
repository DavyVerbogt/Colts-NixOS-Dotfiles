{ ... }: {
  # Unity Hub is packaged directly in nixpkgs as a self-contained derivation
  # (pkgs.unityhub) — no need to hand-roll a buildFHSEnv for it.
  flake.nixosModules.unity = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.unityhub ];
    # Unity Hub's sign-in flow shells out to xdg-open for the browser step;
    # without this it can silently fail. desktop/gtk-settings.nix already
    # enables xdg.portal — this opts into the newer portal-based xdg-open.
    xdg.portal.xdgOpenUsePortal = true;
    # If the "Windows Build Support (Mono)" module fails to install inside
    # Unity Hub, that's the known missing-dependency issue this used to work
    # around with an extraLibs override — but the fix pulled in openssl_1_1,
    # which nixpkgs now refuses to build (EOL, marked insecure). Not baking
    # that back in as a default; if you hit the actual failure, decide
    # deliberately whether `nixpkgs.config.permittedInsecurePackages =
    # [ "openssl-1.1.1w" ];` is a trade you want to make, rather than having
    # it forced on by this file.
  };
}
