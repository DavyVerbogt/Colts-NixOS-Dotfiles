{ ... }: {

  # xdg-desktop-portal doesn't know "niri" as a recognized desktop
  # environment out of the box, so without an explicit backend mapping it
  # has nothing to route portal requests to. Depending on the request type
  # this shows up differently: global shortcuts fail fast (the
  # "Failed to call BindShortcuts (error code 5)" seen in Claude Desktop's
  # logs), while the file-open/file-chooser dialog just hangs waiting on a
  # response that never comes — which matches "does not open any files and
  # then freezes". desktop/gtk-settings.nix already installs
  # xdg-desktop-portal-gtk as a backend; this just tells the portal service
  # to actually use it as the default.
  #
  # ScreenCast is routed separately to xdg-desktop-portal-gnome: gtk's
  # portal doesn't implement org.freedesktop.impl.portal.ScreenCast at all,
  # so Discord/OBS/browser screen-share had no backend whatsoever under
  # niri before this — test it before you need it mid-call, not during one.
  flake.nixosModules.portals = { pkgs, ... }: {
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    xdg.portal.config.common = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
    };
  };
}
