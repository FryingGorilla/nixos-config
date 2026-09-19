{ ... }:

{
  flake.nixosModules.pc = { pkgs, ... }: {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Use Mesa's AMDGPU driver and expose the ROCm OpenCL/HIP runtime.
    hardware.amdgpu.opencl.enable = true;
    nixpkgs.config.rocmSupport = true;

    # The Logitech receiver can signal wake even with its mouse switched off.
    # Match its USB IDs so this follows the receiver when changing ports.
    services.udev.extraRules = ''
      ACTION=="add|bind|change", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="046d", ATTR{idProduct}=="c547", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    '';

    # Reapply immediately before sleep in case a driver enabled wake after udev.
    powerManagement.powerDownCommands = ''
      for device in /sys/bus/usb/devices/*; do
        [ -r "$device/idVendor" ] && [ -r "$device/idProduct" ] || continue
        if [ "$(cat "$device/idVendor")" = 046d ] &&
           [ "$(cat "$device/idProduct")" = c547 ] &&
           [ -w "$device/power/wakeup" ]; then
          echo disabled > "$device/power/wakeup"
        fi
      done
    '';

    environment.systemPackages = with pkgs; [
      clinfo
      rocmPackages.rocminfo
    ];
  };
}
