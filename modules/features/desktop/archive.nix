{ ... }: {

  flake.nixosModules.archive = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      xarchiver # lightweight GTK archive manager — thunar-archive-plugin's backend
      p7zip # .7z (and broad general-purpose) support
      unzip # .zip extraction
      zip # .zip creation
      unrar # .rar extraction
    ];
  };
}
