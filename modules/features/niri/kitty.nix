{...}: {

    # Kitty terminal emulator. niri already binds Mod+Return to it; this installs
    # it system-wide and marks it as the default $TERMINAL for apps that honour it.
    # Imported in hosts/ws01-nix/config.nix as: self.nixosModules.kitty
    flake.nixosModules.kitty = {pkgs, ...}: {
        environment.systemPackages = [ pkgs.kitty ];
        environment.sessionVariables.TERMINAL = "kitty";
    };
}
