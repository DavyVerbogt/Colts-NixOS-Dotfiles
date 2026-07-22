{ inputs, ... }: {
  # Cowork/Dispatch on Linux now run via a native daemon (claude-cowork-service)
  # instead of the QEMU/virtiofsd VM backend chased in
  # claude/cowork-bridge-fix-2026-07-11.md — that VM path is superseded, don't
  # keep debugging virtiofsd/vhost_vsock/kvm-group for this. See
  # https://github.com/patrickjaja/claude-cowork-service
  flake.nixosModules.cowork = { pkgs, ... }: {
    imports = [ inputs.claude-cowork-service.nixosModules.default ];

    services.claude-cowork = {
      enable = true;
      # systemd user services don't inherit your shell PATH, so `claude`
      # has to be handed in explicitly. claude-code is already installed
      # system-wide via dev/editor.nix.
      extraPath = [ pkgs.claude-code ];
    };
  };
}
