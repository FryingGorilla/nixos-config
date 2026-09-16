{ ... }:

{
  flake.nixosModules.ephemeral-root = { lib, ... }: {
    # The root filesystem is RAM-backed. State that should survive a reboot is
    # explicitly bind-mounted from /persist by preservation.
    boot.initrd.systemd.enable = true;

    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = lib.mkDefault [ "size=4G" "mode=755" ];
    };
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persist".neededForBoot = true;

    preservation = {
      enable = true;
      preserveAt."/persist" = {
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];
        directories = [
          "/var/log"
          { directory = "/var/lib/nixos"; inInitrd = true; }
          "/var/lib/systemd/coredump"
          "/var/lib/bluetooth"
          "/var/lib/tailscale"
          "/etc/NetworkManager/system-connections"
          "/etc/ssh"
        ];
        users.karl = {
          directories = [
            "Downloads"
            "Documents"
            "Projects"
            ".config/nixos"
            ".config/Bitwarden"
            ".config/Bitwarden CLI"
            ".config/vesktop"
            ".local/share"
            ".local/state/noctalia"
            ".codex"
            ".ssh"
            ".librewolf"
            ".mozilla"
          ];
          files = [ ".zsh_history" ];
        };
      };
    };

    systemd.tmpfiles.settings.preservation = {
      "/home/karl/.config".d = { user = "karl"; group = "users"; mode = "0755"; };
      "/home/karl/.local".d = { user = "karl"; group = "users"; mode = "0755"; };
    };

    # This service cannot commit through preservation's machine-id bind mount.
    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
  };
}
