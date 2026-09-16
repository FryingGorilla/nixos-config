{ ... }:

let
  lockscreenPosition = { x, y }: {
    cx = x;
    cy = y;
    placement_width = 1.0;
    placement_height = 1.0;
  };
in
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
        lockscreen_widgets = {
          enabled = true;
          schema_version = 2;
          widget_order = [
            "lockscreen-login-box@eDP-1"
            "lockscreen-widget-0000000000000001"
          ];
          grid = {
            cell_size = 16;
            major_interval = 4;
            visible = true;
          };
          widget = {
            "lockscreen-login-box@eDP-1" = lockscreenPosition {
              x = 0.5;
              y = 35.0 / 48.0;
            } // {
              box_height = 128.0;
              box_width = 810.0;
              output = "eDP-1";
              rotation = 0.0;
              type = "login_box";
              settings = {
                background_color = "surface_variant";
                background_opacity = 0.88;
                background_radius = 12.0;
                center_password_text = false;
                input_opacity = 1.0;
                input_radius = 6.0;
                layout = "regular";
                show_caps_lock = true;
                show_keyboard_layout = true;
                show_login_button = true;
                show_media = false;
                show_session_buttons = true;
                show_unlock_hint = true;
                show_weather = false;
              };
            };
            lockscreen-widget-0000000000000001 = lockscreenPosition {
              x = 0.5;
              y = 5.0 / 12.0;
            } // {
              box_height = 128.0;
              box_width = 256.0;
              rotation = 0.0;
              type = "clock";
              settings = {
                center_text = true;
                clock_style = "digital";
                color = "primary";
                format = "{:%H:%M}";
              };
            };
          };
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
