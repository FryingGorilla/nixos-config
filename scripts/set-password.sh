#!/usr/bin/env bash
# Change the current user's password through PAM, then copy an atomically replaced
# shadow file back to Userborn's persistent database.
set -euo pipefail

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

sync_shadow() {
  local username=$1
  [[ $EUID == 0 ]] || die "The shadow sync must run as root."
  [[ ${SUDO_USER:-} == "$username" ]] || die "The sudo caller does not match $username."
  local persistent_dir=/var/lib/nixos/users
  local persistent_shadow=$persistent_dir/shadow
  [[ -f /etc/shadow ]] || die "/etc/shadow does not exist."
  [[ -d $persistent_dir ]] || die "Userborn's persistent database does not exist."
  [[ -f $persistent_shadow ]] || die "Userborn's persistent shadow file does not exist."

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

main() {
  if [[ ${1-} == --help || ${1-} == -h ]]; then
    printf "Usage: bash scripts/set-password.sh\nChange your login and GNOME Keyring password, then store it persistently.\n"
    return
  fi

  if [[ ${1-} == --sync ]]; then
    [[ $# == 2 ]] || die "Invalid internal sync invocation."
    sync_shadow "$2"
    return
  fi

  [[ $# == 0 ]] || die "This script changes the current user's password; use --help."
  [[ $EUID != 0 ]] || die "Run this script as your user, without sudo."

  local username script_path
  username=$(id -un)
  [[ $username != root ]] || die "Refusing to change root's password."
  getent passwd "$username" >/dev/null || die "Local user does not exist: $username"
  script_path=$(realpath -- "${BASH_SOURCE[0]}")

  # Authenticate sudo before changing the login password. passwd must run as the
  # user so PAM can give GNOME Keyring both the old and new passwords.
  sudo -v
  passwd
  sudo bash "$script_path" --sync "$username"
}

main "$@"
