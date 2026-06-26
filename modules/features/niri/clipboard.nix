{ ... }: {

  # Clipboard management feature.
  # wl-clipboard provides wl-copy/wl-paste; wl-clip-persist keeps clipboard
  # contents alive after the source app closes; cliphist maintains history.
  flake.nixosModules.clipboard = { pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      wl-clipboard   # wl-copy / wl-paste
      wl-clip-persist # preserve clipboard after source app exits
      cliphist       # clipboard history daemon
    ];
  };
}
