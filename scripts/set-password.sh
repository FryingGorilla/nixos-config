#!/usr/bin/env bash
# Change a local user's password and copy an atomically replaced shadow file back to
# Userborn's persistent database.
set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

main() {
  if [[ ${1-} == --help || ${1-} == -h ]]; then
    printf "Usage: sudo bash scripts/set-password.sh [USER]\nSet a local user's password persistently; USER defaults to the sudo caller.\n"
    return
  fi
  [[ $# -le 1 ]] || die "Too many arguments. Use --help."
  [[ $EUID == 0 ]] || die "Run with sudo bash scripts/set-password.sh."

  local username=${1:-${SUDO_USER:-}}
  [[ -n $username ]] || die "Specify a username when the sudo caller is unavailable."
  [[ $username != -* ]] || die "Invalid username: $username"
  getent passwd "$username" >/dev/null || die "Local user does not exist: $username"

  local persistent_dir=/var/lib/nixos/users
  local persistent_shadow=$persistent_dir/shadow
  [[ -f /etc/shadow ]] || die "/etc/shadow does not exist."
  [[ -d $persistent_dir ]] || die "Userborn's persistent database does not exist."
  [[ -f $persistent_shadow ]] || die "Userborn's persistent shadow file does not exist."

  passwd "$username"

  # shadow-utils may replace /etc/shadow instead of updating its symlink target.
  # In that case, atomically copy the changed database back to persistent storage.
  if [[ ! /etc/shadow -ef $persistent_shadow ]]; then
    local temporary_shadow
    temporary_shadow=$(mktemp "$persistent_dir/.shadow.XXXXXXXX")
    trap 'rm -f -- "$temporary_shadow"' EXIT
    cp --preserve=mode,ownership,timestamps /etc/shadow "$temporary_shadow"
    mv -f -- "$temporary_shadow" "$persistent_shadow"
    trap - EXIT
    sync -f "$persistent_dir"
  fi

  printf "%s's password is stored persistently.\n" "$username"
}

main "$@"
