{ inputs, self, ... }:
{
  flake.nixosConfigurations.latitude = inputs.nixpkgs.lib.nixosSystem {
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
      ../../hardware/latitude.nix
      self.nixosModules.laptop
      ({ lib, ... }: {
        networking.hostName = lib.mkForce "latitude";
        disko.devices.disk.main.device = lib.mkForce "/dev/sda";
        system.stateVersion = "26.05";
      })
    ];
  };
}
