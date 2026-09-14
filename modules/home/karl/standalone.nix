{ inputs, self, ... }:

{
  flake.homeConfigurations.karl =
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = { inherit inputs; };
      modules = [
        inputs.noctalia.homeModules.default
        self.homeModules.karl
        self.homeModules.karl-desktop
        self.homeModules.karl-programs
        self.homeModules.karl-shell
      ];
    };
}
