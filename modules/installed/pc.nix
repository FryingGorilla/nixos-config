{ inputs, self, ... }:
{
  flake.nixosConfigurations.pc = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = { inherit inputs; };
    modules = [
      inputs.home-manager.nixosModules.default
      inputs.noctalia-greeter.nixosModules.default
      inputs.preservation.nixosModules.default
      inputs.disko.nixosModules.disko
      self.nixosModules.base
      self.nixosModules.desktop
      self.nixosModules.ephemeral-root
      self.nixosModules.karl
      self.nixosModules.disk-layout
      self.nixosModules.installed-system
      ../../hardware/pc.nix
      self.nixosModules.pc
      ({ lib, ... }: {
        networking.hostName = lib.mkForce "pc";
        disko.devices.disk.main.device = lib.mkForce "/dev/nvme0n1";
        system.stateVersion = "26.05";
      })
    ];
  };
}
