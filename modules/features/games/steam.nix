{ inputs, config, ... }:
{
  flake.nixosModules.steam =
    {
      pkgs,
      lib,
      ...
    }:
    let
      # Every profile now defines a full palette (added when home/kitty.nix
      # started reading these too), so MangoHud consistently follows
      # theme.profile like everything else — the `or` fallback below only
      # matters for a future profile that doesn't bother defining every key.
      hex = name: default: lib.removePrefix "#" (config.theme.palette.${name} or default);
    in
    {

      nixpkgs.overlays = [
        inputs.millennium.overlays.default
      ];
      systemd.user.tmpfiles.rules = [
        "d %h/.local/share/millennium/themes 0755 - - -"
      ];
      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = false;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
          xdg-utils
          thunar
        ];
      };

      # Gamemode for performance optimization
      programs.gamemode = {
        enable = true;

        settings = {
          general = {
            renice = 10;
          };

          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
          };
        };
      };

      # Gamescope compositor
      programs.gamescope = {
        enable = false;
        capSysNice = true;
      };

      # Enable 32-bit libraries for games
      hardware.graphics.enable32Bit = true;

      # Gaming packages
      environment.systemPackages = with pkgs; [
        # Launchers
        faugus-launcher

        # Proton/Wine
        protonup-qt
        winetricks
        protontricks
        protonplus

        # Tools
        gamemode

        # Controllers
        sc-controller

        # Performance monitoring
        nvtopPackages.full

        mangohud
      ];

      # Default-application registration (including nxm) now lives in
      # desktop/mimeapps.nix, which owns /etc/xdg/mimeapps.list globally.

      environment.etc."MangoHud/MangoHud.conf".text = ''
        legacy_layout = false
        position = top-left
        width = 270

        # --- Display elements ---
        fps
        frametime
        frame_timing = 1
        gpu_stats
        gpu_temp
        gpu_mem_temp
        gpu_core_clock
        gpu_mem_clock
        vram
        cpu_stats
        cpu_temp
        cpu_power
        gpu_power
        ram

        # --- Font ---
        font_size = 24
        no_small_font = false

        # --- Palette — sourced from theme.palette (theming/profiles/*.nix)
        #     instead of hardcoded here, so it stays in sync with the rest
        #     of the active theme.profile. ---
        background_color = ${hex "void" "0d0d1a"}
        text_color       = dde4ff

        fps_color_above_warn = ${hex "green" "39ff14"}
        fps_color_warn       = ff9500
        fps_color            = ff3030

        gpu_color       = ${hex "cyan" "00e5ff"}
        cpu_color       = ff2d55
        vram_color      = ${hex "accent2" "bf5fff"}
        ram_color       = 5b8af5
        frametime_color = 00bfa5
        engine_color    = ${hex "cyan" "00e5ff"}
        wine_color      = ff7043

        # --- Style ---
        background_alpha = 0.85
        round_corners    = 8
        table_columns    = 3

        # --- Toggles ---
        toggle_hud       = Shift_R+F12
        toggle_fps_limit = Shift_L+F1
      '';

      environment.sessionVariables.MANGOHUD_CONFIGFILE = "/etc/MangoHud/MangoHud.conf";
    };
}
