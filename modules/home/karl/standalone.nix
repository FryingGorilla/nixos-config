{ inputs, self, ... }:

{
  flake.homeConfigurations.karl =
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
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
