{ config, lib, ... }: {

  # Per-device pointer tuning, consumed directly by niri.nix's
  # perSystem-built `input.mouse` settings block the same way
  # desktop/cursor.nix's options are consumed by its `cursor` block.

  options.desktop.mouse = {
    accelProfile = lib.mkOption {
      type = lib.types.enum [ "adaptive" "flat" ];
      default = if config.device.class == "laptop" then "adaptive" else "flat";
      description = "flat = precise 1:1 tracking for a real mouse; adaptive = better for a trackpad.";
    };
    accelSpeed = lib.mkOption {
      type = lib.types.float;
      default = if config.device.class == "laptop" then 0.2 else 0.0;
      description = "libinput accel-speed, range -1.0 to 1.0.";
    };
  };
}
