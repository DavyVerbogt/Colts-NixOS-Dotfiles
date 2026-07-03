{ self, inputs, ... }: {

  flake.nixosModules.claude =
    { pkgs, ... }:
    let
      claudeDesktop =
        inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-with-fhs;
    in
    {
      environment.systemPackages = [
        (pkgs.symlinkJoin {
          name = "claude-desktop-wrapped";
          paths = [ claudeDesktop ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for bin in $out/bin/*; do
              wrapProgram "$bin" --set ELECTRON_OZONE_PLATFORM_HINT wayland
            done
          '';
        })
      ];
    };
}
