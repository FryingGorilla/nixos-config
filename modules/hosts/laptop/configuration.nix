{ ... }:

{
  flake.nixosModules.laptop = { lib, pkgs, ... }: {
    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    home-manager.users.karl = { config, ... }: {
      programs.noctalia.settings.bar.default.end = lib.mkAfter [ "caffeine" ];

      # Follow caffeine through logind without modifying the cached shell package.
      systemd.user.services.caffeine-lid = {
        Unit = {
          Description = "Ignore laptop lid closure while Noctalia caffeine is enabled";
          PartOf = [ config.wayland.systemd.target ];
          # No ordering on Noctalia: it starts after the graphical target,
          # while this target wants us. The helper already polls for inhibitors.
        };
        Service = {
          ExecStart = "${pkgs.python3.withPackages (ps: [ ps.dbus-python ps.pygobject3 ])}/bin/python ${./caffeine-lid.py}";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ config.wayland.systemd.target ];
      };
    };

  };
}
