{ ... }: {
  flake.nixosModules.fetch =
    { pkgs, ... }:
    let
      ozozfetchConfig = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/Chick2D/neofetch-themes/main/normal/ozozfetch";
        hash = "sha256-hbZv0auxzMUIpw4R/qxm6voRX8TzhJq3XrP4LrRj33A=";
      };

      neofetch = pkgs.writeShellScriptBin "neofetch" ''
        ${pkgs.hyfetch}/bin/neowofetch --config ${ozozfetchConfig} "$@"
      '';
    in
    {
      environment.systemPackages = [ neofetch ];
    };
}
