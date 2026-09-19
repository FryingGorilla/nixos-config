{ ... }:

{
  flake.nixosModules.desktop = { pkgs, ... }: {
    programs.niri.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    programs.noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "niri";
        keyboard.layout = "us";
        appearance = {
          # This greeter version only loads wallpaper with a complete Synced palette.
          scheme = "Synced";
          theme_mode = "dark";
          corner_radius_scale = 1.0;
          font_family = "sans-serif";
          palette = {
            error = "#FFB4AB";
            hover = "#CFC3CA";
            on_error = "#690005";
            on_hover = "#352E33";
            on_primary = "#2F3035";
            on_secondary = "#303032";
            on_surface = "#E5E2E2";
            on_surface_variant = "#C7C6CB";
            on_tertiary = "#352E33";
            outline = "#46464B";
            primary = "#C6C6CC";
            secondary = "#C8C6C8";
            shadow = "#000000";
            surface = "#141314";
            surface_variant = "#201F20";
            tertiary = "#CFC3CA";
          };
          wallpaper.path = "${../../assets/wallpapers/dark.png}";
          hide_logo = true;
          scheme_selector_position = "hidden";
        };
      };
    };

    systemd.services.noctalia-greeter-avatar = {
      description = "Set the Noctalia greeter avatar when profile.png exists";
      wantedBy = [ "graphical.target" ];
      before = [ "greetd.service" ];
      after = [ "accounts-daemon.service" ];
      requires = [ "accounts-daemon.service" ];
      unitConfig.ConditionPathExists = "/home/karl/Media/Pictures/profile.png";
      serviceConfig.Type = "oneshot";
      script = ''
        user_path="$(${pkgs.systemd}/bin/busctl call \
          org.freedesktop.Accounts \
          /org/freedesktop/Accounts \
          org.freedesktop.Accounts \
          FindUserByName s karl)"
        user_path="''${user_path#*\"}"
        user_path="''${user_path%%\"*}"

        ${pkgs.systemd}/bin/busctl call \
          org.freedesktop.Accounts \
          "$user_path" \
          org.freedesktop.Accounts.User \
          SetIconFile s /home/karl/Media/Pictures/profile.png
      '';
    };

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.sessionVariables.NIXOS_OZONE_WL = "1";
    environment.systemPackages = [ pkgs.xwayland-satellite ];
  };
}
