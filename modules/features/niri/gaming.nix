# Gaming fixes for niri's scrollable tiling: games should take over the
# screen, never tile into a translucent, blurred, rounded-corner column.
#
# Dendritic module: exposes a top-level option (like niri/shaders.nix does
# for animations) that niri.nix appends to the very END of its window-rules
# expression. Later rules win in niri, so these override the global
# corner-radius/opacity rule and the blur-all rule for game windows only.
{ lib, ... }:
{
  options.niri.gameWindowRules = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    description = ''
      Extra niri window-rules (wrapper settings form, plain data) appended
      after every other rule in niri.nix. Meant for games. When a game
      slips through, find its app-id with `niri msg windows` while it is
      running and add a matcher here.
    '';
    default = [
      {
        matches = [
          # Steam/Proton games: XWayland via xwayland-satellite, WM_CLASS
          # is always steam_app_<appid>. Covers every Proton game and most
          # native Steam games.
          { app-id = "^steam_app_[0-9]+$"; }
          # Wine/umu games launched outside Steam (Faugus etc.): WM_CLASS
          # is usually the Windows executable name. (?i) also catches
          # GAME.EXE. Deliberately does NOT match faugus-launcher itself.
          { app-id = "(?i)\\.exe$"; }
          # Anything wrapped in `gamescope -- %command%`.
          { app-id = "^gamescope$"; }
        ];

        # Take over the whole output instead of tiling into a column.
        open-fullscreen = true;

        # Games must never inherit the theme's translucency, blur, or
        # rounded corners — translucency/blur cost frames and look wrong,
        # and the corner radius clips game pixels.
        opacity = 1.0;
        background-effect.blur = false;
        geometry-corner-radius = 0;
        clip-to-geometry = false;

        # Only takes effect on an output configured with
        # variable-refresh-rate "on-demand"; harmless otherwise.
        # (__GL_VRR_ALLOWED / __GL_GSYNC_ALLOWED are already 1 in
        # niri.nix's nvidia sessionVariables.)
        variable-refresh-rate = true;
      }
    ];
  };
}
