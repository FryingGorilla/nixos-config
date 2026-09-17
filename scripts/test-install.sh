#!/usr/bin/env bash
# Non-destructive tests: source functions only; never invoke installer main.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/install.sh"

for name in pc laptop thinkpad t14-gen3; do check_name "$name"; done
for name in '' ../escape 'pc";' PC trailing-; do
  if (check_name "$name") 2>/dev/null; then
    die "Accepted invalid or reserved name: $name"
  fi
done
if (check_disk /dev/null) 2>/dev/null; then die 'Accepted a non-disk device'; fi

fixture=$(mktemp -d /tmp/install-test.XXXXXXXX)
# A deterministic stand-in for the hardware scanner, without reading this host.
nixos-generate-config() {
  printf '{ lib, ... }: { nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux"; }\n'
}
write_host "$fixture" test-pc /dev/vda pc
write_host "$fixture" test-laptop /dev/nvme0n1 laptop
grep -q 'self.nixosModules.laptop$' "$fixture/modules/installed/test-laptop.nix"
grep -q 'self.nixosModules.pc$' "$fixture/modules/installed/test-pc.nix"
if grep -q 'self.nixosModules.pc$' "$fixture/modules/installed/test-laptop.nix"; then
  die 'Laptop inherited the PC profile'
fi
if grep -q 'self.nixosModules.laptop$' "$fixture/modules/installed/test-pc.nix"; then
  die 'PC inherited the laptop profile'
fi
grep -q 'device = lib.mkForce "/dev/vda"' "$fixture/modules/installed/test-pc.nix"
grep -q 'hostName = lib.mkForce "test-pc"' "$fixture/modules/installed/test-pc.nix"
printf 'Installer tests passed; generated fixtures: %s\n' "$fixture"
