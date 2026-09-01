{ ... }: {
  # VRChat's own Creator Companion doesn't ship a working Linux GUI — only
  # Windows is officially supported, with limited CLI-only behavior
  # elsewhere. ALCOM (built on vrc-get) is the community open-source
  # replacement and IS packaged in nixpkgs (uses the same settings file as
  # VCC, so nothing to migrate). As of nixpkgs 25.05 it has a known native
  # Wayland rendering bug — opens blank or crashes (nixos/nixpkgs#435243);
  # forcing XWayland via GDK_BACKEND=x11 is the documented workaround,
  # wrapped the same way games/minecraft.nix already wraps prismlauncher
  # with makeWrapper for its own Wayland-related env fix.
  #
  # Scope: everything VRChat-specific. Assumes unity.nix has already made the
  # editor launchable from outside Unity Hub — without that FHS wrapper, ALCOM
  # spawns the editor binary directly and it dies on a missing loader.
  #
  # Avatars and worlds are the same setup at this layer. Same editor, same VPM
  # machinery; the Worlds SDK just pulls UdonSharp along with it.
  flake.nixosModules.vrcc =
    { pkgs, lib, ... }:
    let
      # symlinkJoin + wrapProgram, not runCommand + makeWrapper: the latter
      # produces bin-only output, dropping the icons alcom installs into
      # share/icons/hicolor and the .desktop cargo-tauri generates, so the
      # launcher entry vanishes. Same lesson as the ZenConf wrapper.
      #
      # Note the binary is capitalised — mainProgram is "ALCOM". Wrapping it as
      # lowercase `alcom` would leave the .desktop pointing at a name that no
      # longer exists in the output.
      alcom = pkgs.symlinkJoin {
        name = "alcom-wrapped";
        paths = [ pkgs.alcom ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/ALCOM --set GDK_BACKEND x11
        '';
      };

      # VPM listings to register. These are *repositories*, not packages — the
      # package set stays per-project and lives in ALCOM, because VPM resolves
      # versions against a project manifest that Nix has no business touching.
      # Pinning VRCFury here would mean fighting the resolver every time you
      # open someone else's project.
      #
      # This is the one list to edit when you find a new toolmaker. Every URL
      # is present in kurotu/vpm-catalog — don't add unverified listings, a VPM
      # repo can inject editor scripts that run during your builds.
      vpmRepos = [
        # --- Curated / official ---
        "https://vrchat-community.github.io/vpm-listing-curated/index.json"

        # --- Avatars ---
        "https://vcc.vrcfury.com" # VRCFury — non-destructive avatar components
        "https://vpm.nadena.dev/vpm.json" # Modular Avatar (bd_)
        "https://lilxyzw.github.io/vpm-repos/vpm.json" # lilToon
        "https://vpm.thry.dev/index.json" # Thry's editor + Poiyomi tooling
        "https://d4rkc0d3r.github.io/vpm-repos/main.json" # d4rkAvatarOptimizer
        "https://hai-vr.github.io/vpm-listing/index.json" # Haï~ Av3 tooling
        "https://api.vrlabs.dev/listings/category/Essentials" # VRLabs

        # --- Worlds ---
        "https://vrctxl.github.io/VPM/index.json" # Texel — USharpVideo / players
        "https://cyanlaser.github.io/CyanTrigger/index.json" # visual Udon
        "https://cyanlaser.github.io/CyanPlayerObjectPool/index.json"
        "https://orels1.github.io/orels-Unity-Shaders/index.json"
        "https://BlueAmulet.github.io/UdonSharpOptimizer/index.json"

        # --- Linux ---
        # Makes SDK "Build & Test" work for avatars and worlds — out of the box
        # it's Windows-only, since it hands the build to the VRChat client.
        # Harmony-patches the SDK, which is against VRChat's ToS. Registering a
        # listing installs nothing; comment out if you'd rather not have it one
        # click away. Uploading is unaffected and works unpatched.
        "https://befuddledlabs.github.io/LinuxVRChatSDKPatch/index.json"
      ];

      seedRepos = pkgs.writeShellApplication {
        name = "vrchat-vpm-repos";
        runtimeInputs = [ pkgs.vrc-get ];
        text = ''
          known=$(vrc-get repo list || true)
          for url in ${lib.escapeShellArgs vpmRepos}; do
            case "$known" in
              *"$url"*) continue ;;
            esac
            vrc-get repo add "$url" || echo "could not add $url" >&2
                        printf '%s\n' \
              '#!/bin/sh' \
              '# nix-unity-fhs-wrapper' \
              'export LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver/lib32' \
              'export XDG_DATA_DIRS=/run/opengl-driver/share:''${XDG_DATA_DIRS}' \
              'export VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json' \
              'unset GIO_MODULE_DIR GDK_PIXBUF_MODULE_FILE GSETTINGS_SCHEMA_DIR GTK_PATH' \
              "exec -a \"$editor/Unity.real\" \"$fhs\" \"$editor/Unity.real\" \"\$@\"" \
              > "$editor/Unity"            # shellcheck disable=SC2016 -- ${XDG_DATA_DIRS} must reach the
            # generated wrapper unexpanded; it's evaluated when Unity launches.
            # shellcheck disable=SC2016
            # shellcheck disable=SC2016 -- the XDG_DATA_DIRS expansion must
            # reach the generated wrapper unexpanded; it is evaluated when
            # Unity launches, not when this script runs.
            # shellcheck disable=SC2016
            printf '%s\n' \
              '#!/bin/sh' \
              '# nix-unity-fhs-wrapper' \
              'export LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver/lib32' \
              'export XDG_DATA_DIRS=/run/opengl-driver/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}' \
              'export VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json' \
              'unset GIO_MODULE_DIR GDK_PIXBUF_MODULE_FILE GSETTINGS_SCHEMA_DIR GTK_PATH' \
              "exec -a \"$editor/Unity.real\" \"$fhs\" \"$editor/Unity.real\" \"\$@\"" \
              > "$editor/Unity"
          done
        '';
      };
    in
    {
      environment.systemPackages = [
        alcom
        pkgs.vrc-get # CLI client — useful for scripted project setup
        pkgs.dotnet-sdk_8 # C#/Udon# language server backing for VSCodium
      ];

      # A user unit, not an activation script: `vrc-get repo add` fetches each
      # listing over the network, and a nixos-rebuild switch must not block on
      # (or fail from) a dead CDN.
      #
      # vrc-get and ALCOM share ~/.local/share/VRChatCreatorCompanion/settings.json,
      # so anything seeded here shows up in ALCOM's package browser. Additions
      # only — dropping a URL from vpmRepos above leaves it registered; use
      # `vrc-get repo remove` for that. Converging both ways would mean owning
      # settings.json outright, and that file also holds ALCOM's own mutable
      # state.
      systemd.user.services.vrchat-vpm-repos = {
        description = "Register VRChat VPM listings with vrc-get/ALCOM";
        wantedBy = [ "default.target" ];
        after = [
          "network-online.target"
          "unity-fhs-wrap.service"
        ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe seedRepos;
        };
      };

      # Manual, first-run only — not declarable, ALCOM owns this state:
      #
      #  1. ALCOM searches a hard-coded list of Unity Hub locations, none of
      #     which is a Nix store path. Point it at the Hub in Settings.
      #  2. Settings → Default Unity Command-line Arguments → add
      #     `-force-vulkan`, and `-force-gfx-direct` too if the editor still
      #     crashes on colour pickers or package imports (see unity.nix).
      #
      # And one filesystem trap: keep projects on ext4/btrfs, and make sure the
      # mount isn't `noexec`. The SDK's shader compiler plugin fails to load
      # silently under noexec, and the avatar uploads without its stereo shader
      # variants — looks flat to everyone, including you.
    };
}
