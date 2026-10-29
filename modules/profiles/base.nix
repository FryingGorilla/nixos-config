{ inputs, ... }:

{
  flake.nixosModules.base = { pkgs, ... }: {
    imports = [ inputs.vplan.nixosModules.default ];
    programs.vplan = {
      enable = true;
      settings = {
        api_base = "http://127.0.0.1:10531/v1";
        api_key_env = "OPENAI_API_KEY";
        analysis_model = "gpt-6-luna";
        hint_model = "gpt-6-astra";
        feedback_model = "gpt-6.1-sol";
        goals = [ { name = "training"; mode = "practice"; } ];
        eio_archive = "~/Projects/VP/plaan/eio";
        cf_archive = "~/Projects/VP/plaan/codeforces";
        assessments = "~/Projects/VP/plaan/solutions/reports/index.json";
      };
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://noctalia.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
    nixpkgs.config.allowUnfree = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Tallinn";
    i18n.defaultLocale = "en_US.UTF-8";

    programs.zsh.enable = true;

    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };

    # Smart-card reader access for DigiDoc4 and the Web eID native messaging host.
    services.pcscd.enable = true;

    services.tailscale = {
      enable = true;
      openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      curl
      git
      jq
      qdigidoc
      ripgrep
      unzip
      vim
      wget
    ];
  };
}
