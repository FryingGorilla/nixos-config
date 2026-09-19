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
  flake.homeModules.karl-desktop = { config, lib, pkgs, ... }: let
    clearClipboard = pkgs.writeShellScript "clear-clipboard" ''
      ${pkgs.wl-clipboard}/bin/wl-copy --clear
      ${pkgs.wl-clipboard}/bin/wl-copy --primary --clear
      exec ${lib.getExe config.programs.noctalia.package} msg clipboard-clear
    '';
  in {
    home.activation.createScreenshotDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/Media/Pictures/Screenshots"
    '';

    # GUI overrides win over config.toml. Correct only login-box media settings,
    # retaining the user's other widget positions and runtime preferences.
    home.activation.noctaliaLockscreenPrivacy = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.python3.withPackages (ps: [ ps.tomlkit ])}/bin/python3 - <<'PY'
      import os
      from pathlib import Path
      import tempfile
      import tomlkit

      path = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "noctalia/settings.toml"
      if path.exists():
          original = path.read_text()
          document = tomlkit.parse(original)
          for widget in document.get("lockscreen_widgets", {}).get("widget", {}).values():
              if widget.get("type") == "login_box":
                  widget.setdefault("settings", {})["show_media"] = False
          updated = tomlkit.dumps(document)
          if updated != original:
              with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as f:
                  f.write(updated)
                  temporary = Path(f.name)
              try:
                  temporary.chmod(path.stat().st_mode & 0o777)
                  temporary.replace(path)
              finally:
                  temporary.unlink(missing_ok=True)
      PY
    '';

    systemd.user.services.clipboard-expiry = {
      Unit = {
        Description = "Clear clipboard selections and unpinned Noctalia history";
        PartOf = [ "graphical-session.target" ];
        After = [ "noctalia.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = clearClipboard;
      };
    };
    systemd.user.timers.clipboard-expiry = {
      Unit.PartOf = [ "graphical-session.target" ];
      Timer = {
        OnActiveSec = "5min";
        OnUnitActiveSec = "5min";
        AccuracySec = "1s";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        "image/png" = [ "org.gnome.Loupe.desktop" ];
        "image/webp" = [ "org.gnome.Loupe.desktop" ];
        "image/gif" = [ "org.gnome.Loupe.desktop" ];
        "video/mp4" = [ "org.gnome.Showtime.desktop" ];
        "video/webm" = [ "org.gnome.Showtime.desktop" ];
        "video/x-matroska" = [ "org.gnome.Showtime.desktop" ];
      };
    };
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      pictures = "${config.home.homeDirectory}/Media/Pictures";
    };
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
        hooks = {
          started = "${clearClipboard}";
          session_locked = "${clearClipboard}";
        };
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
            "lockscreen-login-box@DP-2"
            "lockscreen-widget-0000000000000001"
          ];
          grid = {
            cell_size = 16;
            major_interval = 4;
            visible = true;
          };
          widget = let
            loginBox = output: lockscreenPosition {
              x = 0.5;
              y = 35.0 / 48.0;
            } // {
              box_height = 128.0;
              box_width = 810.0;
              inherit output;
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
          in {
            "lockscreen-login-box@eDP-1" = loginBox "eDP-1";
            "lockscreen-login-box@DP-2" = loginBox "DP-2";
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
