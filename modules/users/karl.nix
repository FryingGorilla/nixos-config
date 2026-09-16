{ inputs, self, ... }:

{
  flake.nixosModules.karl = { pkgs, ... }: {
    users.users.karl = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
      shell = pkgs.zsh;
    };

    home-manager = {
      # Preserve existing files when Home Manager takes over their configuration.
      backupFileExtension = "before-home-manager";
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit inputs; };
      sharedModules = [
        inputs.noctalia.homeModules.default
        self.homeModules.karl
        self.homeModules.karl-ai
        self.homeModules.karl-desktop
        self.homeModules.karl-programs
        self.homeModules.karl-shell
      ];
      users.karl = { };
    };
  };
}
