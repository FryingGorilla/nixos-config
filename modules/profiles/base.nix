{ ... }:

{
  flake.nixosModules.base = { pkgs, ... }: {
    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://noctalia.cachix.org" ];
      trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
    nixpkgs.config.allowUnfree = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Tallinn";
    i18n.defaultLocale = "en_US.UTF-8";

    programs.zsh.enable = true;

    # Smart-card reader access for the Web eID native messaging host.
    services.pcscd.enable = true;

    environment.systemPackages = with pkgs; [
      curl
      git
      jq
      ripgrep
      unzip
      vim
      vscode
      wget
    ];
  };
}
