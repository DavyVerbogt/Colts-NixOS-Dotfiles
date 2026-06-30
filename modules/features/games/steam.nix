{ inputs, ... }:
{
  flake.nixosModules.steam =
    {
      pkgs,
      lib,
      ...
    }:
    let
      nexusModsApp = pkgs.appimageTools.wrapType2 {
        pname = "nexusmods-app";
        version = "0.10.0";
        src = pkgs.fetchurl {
          url = "https://github.com/Nexus-Mods/NexusMods.App/releases/latest/download/nexusmods-app.AppImage";
          sha256 = pkgs.lib.fakeHash;
        };
      };
    in
    {
      nixpkgs.overlays = [
        inputs.millennium.overlays.default
      ];

      programs.steam = {
        enable = true;
        package = pkgs.millennium-steam;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = false;
        extraCompatPackages = with pkgs; [
          proton-ge-bin
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
      environment.systemPackages =
        [
          nexusModsApp
          (pkgs.makeDesktopItem {
            name = "nexusmods-app";
            desktopName = "Nexus Mods App";
            exec = "${nexusModsApp}/bin/nexusmods-app %u";
            icon = "nexusmods-app";
            categories = [ "Game" ];
            mimeTypes = [ "x-scheme-handler/nxm" ];
          })
        ]
        ++ (with pkgs; [
          # Launchers
          faugus-launcher

          # Proton/Wine
          protonup-qt
          winetricks

          # Tools
          gamemode

          # Controllers
          sc-controller

          # Performance monitoring
          nvtopPackages.full

          mangohud
        ]);

      environment.etc."xdg/mimeapps.list".text = ''
        [Default Applications]
        x-scheme-handler/nxm=nexusmods-app.desktop
      '';

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

        # --- Cyberpunk color palette ---
        background_color = 0d0d1a
        text_color       = dde4ff

        fps_color_above_warn = 39ff14   # neon green  — good
        fps_color_warn       = ff9500   # amber       — warn
        fps_color            = ff3030   # red         — bad

        gpu_color       = 00e5ff   # cyan
        cpu_color       = ff2d55   # hot pink
        vram_color      = bf5fff   # purple
        ram_color       = 5b8af5   # electric blue
        frametime_color = 00bfa5   # teal
        engine_color    = 00e5ff   # cyan
        wine_color      = ff7043   # orange (for Proton games)

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
