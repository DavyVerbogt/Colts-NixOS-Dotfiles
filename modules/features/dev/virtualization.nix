{ ... }: {
  # Opt-in — NOT added to ws01-nixConfig's imports by default. Add
  # `virtualization` to that imports list yourself if/when you want it.
  #
  # Windows 11 VM for testing Visual Studio / M365 / Outlook / Edge — a
  # "close to bare metal" libvirt/KVM guest. Colt chose virtio-gpu + SPICE
  # over GPU passthrough: ws01-nix has a single Nvidia GPU shared with the
  # host (hardware/nvidia.nix), so passing it through would mean the host
  # loses its display whenever the VM is running, plus VFIO hook scripts to
  # unbind/rebind the driver on every start/stop. host-passthrough CPU +
  # virtio disk/net gets VS/Office/Edge feeling native for everything except
  # GPU-bound 3D work, which was explicitly out of scope here.
  #
  # This only prepares the HOST. Nix cannot fetch or hold a license for a
  # Windows ISO — get one yourself from microsoft.com, then run
  # `create-win11-vm /path/to/Win11.iso` (installed below via perSystem).
  #
  # users.users.colt.extraGroups += libvirtd/kvm means you need to log
  # out/in (or reboot) once after the first rebuild for group membership to
  # take effect.
  flake.nixosModules.virtualization =
    { pkgs, ... }:
    let
      # `virsh start` errors if the domain is already running — the `|| true`
      # swallows that so double-clicking the icon while it's already open
      # just refocuses virt-viewer instead of erroring out. --wait makes
      # virt-viewer itself block/retry until the domain is actually up
      # instead of racing the `virsh start` above.
      launchWin11Vm = pkgs.writeShellScriptBin "launch-win11-vm" ''
        set -euo pipefail
        ${pkgs.libvirt}/bin/virsh --connect qemu:///system start win11-testvm 2>/dev/null || true
        exec ${pkgs.virt-viewer}/bin/virt-viewer --connect qemu:///system --wait win11-testvm
      '';

      # Domain name here MUST match `--name win11-testvm` in create-win11-vm
      # below — if you ever rename the VM (virsh domrename), update both.
      win11DesktopItem = pkgs.makeDesktopItem {
        name = "win11-testvm";
        desktopName = "Windows 11 (Test VM)";
        comment = "Visual Studio / M365 / Outlook / Edge testing VM";
        exec = "${launchWin11Vm}/bin/launch-win11-vm";
        # virt-manager's package ships this icon in the hicolor theme;
        # [verify: icon actually resolves — if it renders as a blank/generic
        # icon in Noctalia's launcher, swap for a plain XDG name like
        # "computer" instead].
        icon = "virt-manager";
        categories = [ "System" "Utility" ];
        terminal = false;
      };
    in
    {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          ovmf = {
            enable = true;
            # OVMFFull ships the secure-boot-capable firmware + Microsoft's
            # signing keys pre-enrolled in the vars template — Windows 11
            # Setup's secure-boot check fails against the plain OVMF.fd.
            packages = [ pkgs.OVMFFull.fd ];
          };
          # TPM 2.0 emulation — Windows 11 Setup hard-refuses to install
          # without a TPM present at all (real or emulated).
          swtpm.enable = true;
        };
      };

      # Lets you hot-plug a USB device (e.g. a license dongle, a webcam for
      # Teams) from the host straight into the running VM via virt-viewer.
      virtualisation.spiceUSBRedirection.enable = true;

      programs.virt-manager.enable = true;

      users.users.colt.extraGroups = [ "libvirtd" "kvm" ];

      environment.systemPackages = with pkgs; [
        virt-viewer
        spice-gtk
        # Windows Setup has zero built-in driver for a virtio disk/NIC — it
        # can't even see a disk to install onto without this. Mounted as a
        # second CD-ROM by the launcher script below.
        virtio-win # [verify: attr name — `nix search nixpkgs virtio-win`]
        swtpm
        launchWin11Vm
        win11DesktopItem
      ];

      # NixOS's libvirtd module does NOT auto-create the default storage
      # pool on a fresh system — virt-install fails with "Storage pool not
      # found: no pool with matching name 'default'" without this existing
      # and started first. Idempotent: safe to run on every boot.
      systemd.services.libvirtd-default-pool = {
        description = "Ensure libvirt's default storage pool exists and is started";
        after = [ "libvirtd.service" ];
        requires = [ "libvirtd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.Type = "oneshot";
        script = ''
          if ! ${pkgs.libvirt}/bin/virsh pool-info default >/dev/null 2>&1; then
            ${pkgs.libvirt}/bin/virsh pool-define-as default dir --target /var/lib/libvirt/images
            ${pkgs.libvirt}/bin/virsh pool-autostart default
          fi
          ${pkgs.libvirt}/bin/virsh pool-start default 2>/dev/null || true
        '';
      };
    };

  perSystem = { pkgs, ... }: {
    # Defaults: 8 vCPUs / 16GiB RAM / 128GiB disk — adjust to taste, these
    # are just sane starting points, not read from your actual host specs
    # (I don't have those). host-passthrough exposes your real AMD CPU
    # feature set to the guest instead of QEMU's lowest-common-denominator
    # qemu64 — this is most of what "close to bare metal" means for
    # CPU-bound work like compiling in Visual Studio.
    #
    # virt-install flag syntax (--boot uefi,firmware.feature0...,
    # --tpm backend.type=emulator) is current as of recent libvirt/virtinst
    # — [verify: `virt-install --boot=help` / `--tpm=help` against your
    # installed version before relying on this] since these flags have
    # changed shape across virtinst releases.
    packages.CreateWin11Vm = pkgs.writeShellScriptBin "create-win11-vm" ''
      set -euo pipefail
      if [ $# -lt 1 ]; then
        echo "usage: create-win11-vm /path/to/Win11.iso [vcpus] [ram-mib] [disk-gib]" >&2
        exit 1
      fi
      WIN_ISO="$1"
      VCPUS="''${2:-8}"
      RAM="''${3:-16384}"
      DISK="''${4:-128}"

      ${pkgs.virt-manager}/bin/virt-install \
        --connect qemu:///system \
        --name win11-testvm \
        --os-variant win11 \
        --vcpus "$VCPUS" \
        --cpu host-passthrough \
        --memory "$RAM" \
        --disk size="$DISK",bus=virtio,cache=writeback,discard=unmap \
        --cdrom "$WIN_ISO" \
        --disk ${pkgs.virtio-win}/share/virtio-win/virtio-win.iso,device=cdrom \
        --network network=default,model=virtio \
        --graphics spice,gl=off \
        --video virtio \
        --sound ich9 \
        --tpm backend.type=emulator,backend.version=2.0 \
        --boot uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=yes \
        --features smm=on \
        --channel spicevmc \
        --noautoconsole

      echo "Created 'win11-testvm'. Connect with: virt-viewer --connect qemu:///system win11-testvm"
      echo "In Windows Setup, when it says it can't find a disk to install to:"
      echo "  Load driver -> browse the second CD-ROM (virtio-win) -> viostor/w11/amd64"
      echo "  then repeat for netkvm/w11/amd64 so networking works after install."
      echo "After Windows boots, install spice-guest-tools inside the VM (from"
      echo "the spice-webdavd/spice-vdagent project) for clipboard sync + auto-resize."
    '';
  };
}
