{ ... }: {

  flake.nixosModules.thunar = { pkgs, ... }: {

    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin # right-click compress/extract
        thunar-volman # automount removable media
        thunar-media-tags-plugin # view/edit audio file tags (ID3, OGG) in file properties
      ];
    };
    programs.xfconf.enable = true; # persist Thunar preferences across launches
    services.gvfs.enable = true; # trash, network shares, MTP devices
    services.tumbler.enable = true; # thumbnail generation for images/video
  };
}
