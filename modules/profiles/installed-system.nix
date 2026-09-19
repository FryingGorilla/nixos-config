{ ... }:
{
  flake.nixosModules.installed-system = { lib, ... }: {
    # Userborn maintains /etc account-file symlinks into persistent storage.
    # Persist the whole directory so atomic password-file replacements work.
    services.userborn = {
      enable = true;
      passwordFilesLocation = "/var/lib/nixos/users";
    };
    users.mutableUsers = true;
    users.users.karl.initialPassword = "12345";
    users.users.karl.uid = 1000;
    users.users.root.hashedPassword = "!";

    # Let user-run passwd changes re-encrypt the login keyring with the new
    # password. Running passwd as root cannot provide the old keyring password.
    security.pam.services.passwd.enableGnomeKeyring = true;
    # "sufficient" returns before pam_gnome_keyring sees the new password.
    security.pam.services.passwd.rules.password.unix.control = lib.mkForce "required";

    preservation.preserveAt."/persist".directories = [
      { directory = "/var/lib/userborn"; inInitrd = true; }
    ];

    # Limit simultaneous local builds on the laptop. Installation also needs
    # these options on the live environment's Nix commands (see README).
    nix.settings = {
      max-jobs = 1;
      cores = 2;
    };
  };
}
