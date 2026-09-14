{ ... }:

{
  flake.nixosModules.disk-layout = { ... }: {
    disko.devices.nodev."/" = {
      fsType = "tmpfs";
      device = "none";
      mountOptions = [ "size=4G" "mode=755" ];
    };
    disko.devices.disk.main = {
      # The installer supplies the selected disk in each generated host module.
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0077" "dmask=0077" ];
            };
          };
          swap = {
            size = "16G";
            content = {
              type = "swap";
              resumeDevice = true;
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];
              subvolumes = {
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "noatime" "compress=zstd" ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "noatime" "compress=zstd" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
