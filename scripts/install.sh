#!/usr/bin/env bash
# Run from a NixOS live USB. No disk is modified until the ERASE confirmation.
set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

check_name() {
  [[ $1 =~ ^[a-z][a-z0-9-]{0,62}$ && $1 != *- ]] || die "Use a hostname starting with a letter, containing lowercase letters, digits and hyphens."
}

check_disk() {
  local disk=$1
  [[ -b $disk ]] || die "Not a block device: $disk"
  [[ $(lsblk -dnro TYPE "$disk") == disk ]] || die "Select a whole disk."
  [[ $(lsblk -dnro RO "$disk") == 0 ]] || die "The disk is read-only."
  # Includes mounted partitions, device-mapper children, and active swap.
  if lsblk -nrpo MOUNTPOINTS "$disk" | grep -q '[^[:space:]]'; then
    die "The disk has mounted filesystems or active swap. Unmount it first."
  fi
  [[ $(lsblk -bdnro SIZE "$disk") -ge 68719476736 ]] || die "Use a disk of at least 64 GiB."
}

write_host() {
  local tree=$1 name=$2 disk=$3 profile=$4
  mkdir -p "$tree/modules/installed" "$tree/hardware"
  nixos-generate-config --show-hardware-config --no-filesystems > "$tree/hardware/$name.nix"
  # Names and paths have been restricted to characters safe in Nix strings.
  cat > "$tree/modules/installed/$name.nix" <<EOF
{ inputs, self, ... }:
{
  flake.nixosConfigurations.$name = inputs.nixpkgs.lib.nixosSystem {
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
      ../../hardware/$name.nix
EOF
  if [[ $profile == laptop ]]; then
    printf '      self.nixosModules.laptop\n' >> "$tree/modules/installed/$name.nix"
  fi
  cat >> "$tree/modules/installed/$name.nix" <<EOF
      ({ lib, ... }: {
        networking.hostName = lib.mkForce "$name";
        disko.devices.disk.main.device = lib.mkForce "$disk";
        system.stateVersion = "26.05";
      })
    ];
  };
}
EOF
}

main() {
  if [[ ${1-} == --help || ${1-} == -h ]]; then
    printf 'Usage: sudo bash scripts/install.sh\nInteractive fresh install from a NixOS UEFI live USB; erases the selected disk.\n'
    return
  fi
  [[ $# == 0 ]] || die "Unknown arguments. Use --help."
  [[ $EUID == 0 ]] || die "Run with sudo bash scripts/install.sh."
  [[ -d /sys/firmware/efi ]] || die "Boot the USB installer in UEFI mode."
  [[ $(uname -m) == x86_64 ]] || die "This repository currently supports x86_64 machines."
  mountpoint -q /iso || die "Run from a NixOS live USB installer, not the installed OS."
  for tool in nix nixos-install nixos-generate-config lsblk findmnt swapon udevadm jq; do
    command -v "$tool" >/dev/null || die "Missing installer tool: $tool"
  done
  [[ -t 0 ]] || die "An interactive terminal is required."
  if findmnt -rn -o TARGET | grep -qE '^/mnt(/|$)'; then
    die "/mnt already contains mounts. Reboot the installer before a fresh attempt."
  fi

  local repo name profile disk answer stage disko_script target swap_device
  repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
  [[ -f $repo/flake.lock ]] || die "Run the script from a complete repository checkout."
  read -r -p 'Machine name (for example pc or thinkpad): ' name
  check_name "$name"
  [[ ! -e $repo/modules/installed/$name.nix ]] || die "A configuration for $name already exists; choose a new name."
  read -r -p 'Machine type [laptop/pc] (default laptop): ' profile
  profile=${profile:-laptop}
  [[ $profile == laptop || $profile == pc ]] || die "Choose laptop or pc."
  lsblk -o NAME,SIZE,MODEL,TRAN,MOUNTPOINTS
  printf '\nAvailable stable disk names:\n'
  ls -l /dev/disk/by-id/ | grep -v -- '-part' || true
  read -r -p 'Target disk (/dev/disk/by-id/... or /dev/nvme0n1): ' disk
  [[ $disk =~ ^/dev/[a-zA-Z0-9_./:+-]+$ ]] || die "Invalid disk path."
  disk=$(readlink -f -- "$disk")
  check_disk "$disk"
  # Duplicate partition labels would make Disko's /dev/disk/by-partlabel paths
  # ambiguous. Require other installations with this layout to be disconnected.
  local partition
  while IFS= read -r partition; do
    if ! lsblk -nrpo NAME "$disk" | grep -Fxq "$partition"; then
      die "Another disk has this layout ($partition). Disconnect it before installing."
    fi
  done < <(lsblk -Jpo NAME,PARTLABEL | jq -r '.. | objects | select((.partlabel? // "") | startswith("disk-main-")) | .name')

  stage=$(mktemp -d /tmp/nixos-install.XXXXXXXX)
  printf 'Preparing configuration in %s\n' "$stage"
  cp -a "$repo/." "$stage/"
  write_host "$stage" "$name" "$disk" "$profile"
  local -a nix_flags=(--extra-experimental-features 'nix-command flakes' --accept-flake-config --max-jobs 1 --cores 2)
  printf '\nValidating the system and building the partitioning tool before erasing anything...\n'
  nix eval "${nix_flags[@]}" --raw "path:$stage#nixosConfigurations.$name.config.system.build.toplevel.drvPath" >/dev/null
  disko_script=$(nix build "${nix_flags[@]}" --no-link --print-out-paths \
    "path:$stage#nixosConfigurations.$name.config.system.build.diskoScript")
  [[ -x $disko_script ]] || die "Disko did not produce an executable."

  lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINTS "$disk"
  printf '\nThis will ERASE ALL DATA on %s and install %s (%s).\n' "$disk" "$name" "$profile"
  printf 'Layout: 1 GiB EFI, 16 GiB swap, Btrfs /nix and /persist, tmpfs /.\n'
  read -r -p "Type ERASE $disk to continue: " answer
  [[ $answer == "ERASE $disk" ]] || die "Cancelled; no disk was modified."
  check_disk "$disk"
  "$disko_script"
  udevadm settle
  for target in /mnt /mnt/nix /mnt/persist /mnt/boot; do
    mountpoint -q "$target" || die "Expected mount missing: $target. Installation stopped."
  done
  # Resolve the swap partition from the selected disk, not a possibly duplicate label.
  swap_device=$(lsblk -Jpo NAME,PARTLABEL "$disk" | jq -r '.. | objects | select(.partlabel? == "disk-main-swap") | .name')
  [[ -b $swap_device ]] || die "Could not identify the new swap partition."
  if ! swapon --show=NAME --noheadings | grep -Fxq "$swap_device"; then
    swapon "$swap_device"
  fi

  target=/mnt/persist/home/karl/.config/nixos
  install -d "$target" /mnt/persist/install-tmp
  cp -a "$stage/." "$target/"
  chown -R 1000:100 /mnt/persist/home/karl
  printf '\nInstalling to disk. If this fails, leave mounts intact and retry:\n'
  printf 'sudo env TMPDIR=/mnt/persist/install-tmp nixos-install --root /mnt --no-root-passwd --flake path:%s#%s --option accept-flake-config true --max-jobs 1 --cores 2\n\n' "$target" "$name"
  TMPDIR=/mnt/persist/install-tmp nixos-install --root /mnt --no-root-passwd \
    --flake "path:$target#$name" --option accept-flake-config true --max-jobs 1 --cores 2
  printf '\nInstallation complete. Reboot and remove the USB.\nLog in as karl / 12345, then run passwd.\n'
  printf 'Rebuild from ~/.config/nixos with: sudo nixos-rebuild switch --accept-flake-config --flake path:.#%s\n' "$name"
  printf 'Generated hardware and host files are in hardware/%s.nix and modules/installed/%s.nix; commit them after installation.\n' "$name" "$name"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  main "$@"
fi
