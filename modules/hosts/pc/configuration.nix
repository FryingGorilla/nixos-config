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

    environment.systemPackages = with pkgs; [
      clinfo
      rocmPackages.rocminfo
    ];
  };
}
