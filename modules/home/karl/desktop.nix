{ ... }:

{
  flake.homeModules.karl-desktop = { pkgs, ... }: {
    programs.kitty = {
      enable = true;
      settings.confirm_os_window_close = 0;
    };

    gtk.enable = true;
    home.pointerCursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };

    programs.noctalia = {
      enable = true;
      settings = {
        backdrop.enabled = true;
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Rosé Pine";
        };
        bar.default = {
          widget_spacing = 16;
          start = [ "tray" "notifications" "workspaces" ];
          center = [ "clock" ];
          end = [
            "clipboard"
            "network"
            "bluetooth"
            "volume"
            "brightness"
            "battery"
            "session"
          ];
        };
        shell = {
          polkit_agent = true;
          setup_wizard_enabled = false;
        };
        wallpaper = {
          enabled = true;
          default.path = "${../../../assets/wallpapers/triangular.png}";
        };
      };
      systemd.enable = true;
    };

    xdg.configFile."niri/config.kdl".source =
      pkgs.runCommand "niri-config-checked"
        { nativeBuildInputs = [ pkgs.niri ]; }
        ''
          niri validate --config ${./niri-config.kdl}
          cp ${./niri-config.kdl} $out
        '';
  };
}
