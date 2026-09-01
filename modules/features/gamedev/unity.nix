{ ... }: {
  # Unity Hub is packaged directly in nixpkgs as a self-contained derivation
  # (pkgs.unityhub) — no need to hand-roll a buildFHSEnv for it.
  #
  # This file owns one thing: making the Unity editor runnable on this machine.
  # That includes the FHS wrapper below, which exists because Unity is an
  # FHS-only binary — not because of VRChat. Anything VRChat-specific (ALCOM,
  # VPM listings, the SDK) belongs in vrchat.nix, which assumes only that the
  # editor here is launchable by something other than the Hub.
  flake.nixosModules.unity =
    { pkgs, lib, ... }:
    let
      # Globs every installed editor rather than pinning 2022.3.22f1, so a
      # second version installed for an older project gets wrapped too.
      #
      # Idempotent via the marker comment: a Hub-side reinstall writes a fresh
      # ELF with no marker and gets re-wrapped on the next run.
      #
      # argv[0] must still look like the real binary path — Unity derives its
      # Data/ directory from argv[0], not from /proc/self/exe.
      wrapUnity = pkgs.writeShellApplication {
        name = "unity-fhs-wrap";
        runtimeInputs = [ pkgs.gnugrep ];
        text = ''
          shopt -s nullglob
                   fhs="${pkgs.unityhub.fhsEnv}/bin/unityhub-fhs-env"

                   for editor in "$HOME"/Unity/Hub/Editor/*/Editor; do
                     [ -x "$editor/Unity" ] || continue
                     if grep -q nix-unity-fhs-wrapper "$editor/Unity" 2>/dev/null; then
                       continue
                     fi

                     mv "$editor/Unity" "$editor/Unity.real"

           
                     printf '%s\n' \
                       '#!/bin/sh' \
                       '# nix-unity-fhs-wrapper' \
                       'export LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver/lib32' \
                       "exec -a \"$editor/Unity.real\" \"$fhs\" \"$editor/Unity.real\" \"\$@\"" \
                       > "$editor/Unity"

                     chmod 755 "$editor/Unity"
                     echo "wrapped $editor/Unity"
                   done
        '';
      };
    in
    {
      environment.systemPackages = [ pkgs.unityhub ];

      # Most VRChat avatar assets ship with Japanese filenames, and the editor
      # renders them as tofu boxes without a CJK face inside the FHS sandbox —
      # the fontconfig in there can't see system fonts. corefonts/dejavu/
      # liberation are already bundled; ipafont is the missing piece.
      #
      # An overlay rather than an inline `.override` on the line above, so that
      # anything else reaching for pkgs.unityhub (the fhsEnv in wrapUnity, most
      # importantly) gets the same derivation instead of a second closure.
      # Drop this block if you don't want the extra font dependency.
      nixpkgs.overlays = [
        (_final: prev: {
          unityhub = prev.unityhub.override { extraPkgs = p: [ p.ipafont ]; };
        })
      ];

      # Unity Hub's sign-in flow shells out to xdg-open for the browser step;
      # without this it can silently fail. desktop/gtk-settings.nix already
      # enables xdg.portal — this opts into the newer portal-based xdg-open.
      xdg.portal.xdgOpenUsePortal = true;

      # If the "Windows Build Support (Mono)" module fails to install inside
      # Unity Hub, that's the known missing-dependency issue this used to work
      # around with an extraLibs override — but the fix pulled in openssl_1_1,
      # which nixpkgs now refuses to build (EOL, marked insecure). Not baking
      # that back in as a default; if you hit the actual failure, decide
      # deliberately whether `nixpkgs.config.permittedInsecurePackages =
      # [ "openssl-1.1.1w" ];` is a trade you want to make, rather than having
      # it forced on by this file.

      # pkgs.unityhub is a bubblewrap wrapper that fabricates an FHS root. An
      # editor the Hub installs inherits that env ONLY when the Hub itself
      # launches it — anything else (ALCOM, a terminal, a .desktop entry)
      # spawns ~/Unity/Hub/Editor/<ver>/Editor/Unity directly, where it can't
      # find its loader and dies. This swaps that binary for a script that
      # re-enters the FHS env.
      #
      # A user unit rather than system.activationScripts + runuser: the target
      # lives in $HOME and only exists after an interactive Hub install, so
      # there's nothing to do at switch time anyway.
      #
      # RemainAfterExit means this runs once per login. Install an editor
      # through the Hub mid-session and nothing will be able to launch it until
      # `systemctl --user restart unity-fhs-wrap`.
      systemd.user.services.unity-fhs-wrap = {
        description = "Wrap Hub-installed Unity editors in unityhub's FHS env";
        wantedBy = [ "default.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = lib.getExe wrapUnity;
        };
      };

      # Unity is X11-only, so it runs under XWayland no matter what the parent
      # process sets. On this machine that means:
      #
      #  1. It's subject to the shared-PID XWayland freeze documented in
      #     claude/xwayland-clients-freeze-on-workspace-switch.md — don't
      #     switch niri workspaces mid-build.
      #  2. Drag-and-drop from a Wayland file manager fails with "Failed
      #     copying file". Use Assets → Import Package, or launch the file
      #     manager with WAYLAND_DISPLAY= set.
      #  3. Nvidia: the editor crashes on colour pickers and package imports on
      #     the default GL path. Pass `-force-vulkan`, then `-force-gfx-direct`
      #     if it persists. Where you set that depends on the launcher — for
      #     ALCOM see vrchat.nix.
    };
}
