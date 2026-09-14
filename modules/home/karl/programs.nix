{ ... }:

{
  flake.homeModules.karl-programs = { pkgs, ... }: {
    programs.librewolf = {
      enable = true;
      policies.EncryptedMediaExtensions = {
        Enabled = true;
        Locked = true;
      };
      settings = {
        "media.gmp-provider.enabled" = true;
        "media.gmp-widevinecdm.enabled" = true;
        "media.gmp-widevinecdm.visible" = true;
        "media.gmp-manager.updateEnabled" = true;
        "media.gmp-manager.url" = "https://aus5.mozilla.org/update/3/GMP/%VERSION%/%BUILD_ID%/%BUILD_TARGET%/%LOCALE%/%CHANNEL%/%OS_VERSION%/%DISTRIBUTION%/%DISTRIBUTION_VERSION%/update.xml";
      };
      nativeMessagingHosts = [ pkgs.web-eid-app ];
      policies.ExtensionSettings = {
        # LibreWolf's bundled uBlock Origin.
        "uBlock0@raymondhill.net".private_browsing = true;
        # IDs verified against Mozilla Add-ons; install signed releases from AMO.
        "{26b4f076-089c-4c69-8497-44b7e5c9faef}" = {
          private_browsing = true;
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/socialfocus/latest.xpi";
        };
        "{2662ff67-b302-4363-95f3-b050218bd72c}" = {
          private_browsing = true;
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/untrap-for-youtube/latest.xpi";
        };
        "{cb31ec5d-c49a-4e5a-b240-16c767444f62}" = {
          private_browsing = true;
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/indie-wiki-buddy/latest.xpi";
        };
        # RIA's official extension, linked from ID.ee's browser setup guide.
        "{e68418bc-f2b0-4459-a9ea-3e72b6751b07}" = {
          private_browsing = true;
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/web-eid-webextension/latest.xpi";
        };
      };
      policies.Preferences."widget.disable-swipe-tracker" = {
        Value = true;
        Status = "locked";
      };
      # Allow only Web eID on Firefox's quarantined (sensitive) sites.
      policies.Preferences."extensions.quarantineIgnoredByUser.{e68418bc-f2b0-4459-a9ea-3e72b6751b07}" = {
        Value = true;
        Status = "locked";
      };
    };

    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
      extraPackages = [ pkgs.xdg-utils pkgs.wl-clipboard ];
      settings = {
        mgr = {
          ratio = [ 1 3 4 ];
          sort_by = "natural";
          sort_dir_first = true;
          show_hidden = true;
          show_symlink = true;
          linemode = "size";
          scrolloff = 5;
        };
        preview = {
          wrap = "yes";
          tab_size = 2;
          max_width = 1600;
          max_height = 1200;
        };
      };
      theme = {
        mgr = {
          cwd = { fg = "#89b4fa"; bold = true; };
          border_style = { fg = "#585b70"; };
          marker_copied = { fg = "#a6e3a1"; bg = "#a6e3a1"; };
          marker_cut = { fg = "#f38ba8"; bg = "#f38ba8"; };
          marker_selected = { fg = "#f9e2af"; bg = "#f9e2af"; };
        };
        mode = {
          normal_main = { fg = "#1e1e2e"; bg = "#89b4fa"; bold = true; };
          select_main = { fg = "#1e1e2e"; bg = "#a6e3a1"; bold = true; };
          unset_main = { fg = "#1e1e2e"; bg = "#f38ba8"; bold = true; };
        };
        status.overall = { fg = "#cdd6f4"; bg = "#1e1e2e"; };
      };
    };

    # Supply the icon glyphs used by Yazi and the shell prompt.
    fonts.fontconfig.enable = true;

    programs.vesktop = {
      enable = true;
      settings = {
        discordBranch = "stable";
        tray = true;
        minimizeToTray = true;
        autoStartMinimized = true;
        openLinksWithElectron = false;
        staticTitle = true;
        enableMenu = false;
        enableShadow = false;
        enableRoundedCorners = false;
        disableSmoothScroll = false;
        hardwareAcceleration = true;
        hardwareVideoAcceleration = true;
        arRPC = false;
        appBadge = true;
        enableTaskbarFlashing = false;
        disableMinSize = true;
        clickTrayToShowHide = true;
        nativeTitleBar = false;
        enableSplashScreen = false;
        splashTheming = false;
        splashPixelated = false;
        spellCheckLanguages = [ "en-US" ];
        transparencyOption = "none";
        webRTCIPHandlingPolicy = "default";
      };
      vencord = {
        useSystem = true;
        settings = {
          autoUpdate = false;
          autoUpdateNotification = false;
          useQuickCss = false;
          enabledThemes = [ ];
          # Official Midnight build; receives upstream Discord compatibility fixes.
          themeLinks = [
            "https://refact0r.github.io/midnight-discord/build/midnight.css"
          ];
          plugins = {
            BetterUploadButton.enabled = true;
            CopyFileContents.enabled = true;
            MemberCount.enabled = true;
            ReadAllNotificationsButton.enabled = true;
            NoTrack.enabled = true;
            NoF1.enabled = true;
            VolumeBooster.enabled = true;
            Translate.enabled = true;
            TenorGifSearch.enabled = true;
            ShowMeYourName.enabled = true;
            ShowHiddenThings.enabled = true;
            ShowHiddenChannels.enabled = true;
            ShikiCodeblocks.enabled = true;
            ServerInfo.enabled = true;
            FixYoutubeEmbeds.enabled = true;
            FixSpotifyEmbeds.enabled = true;
            ForceOwnerCrown.enabled = true;
            ExpressionCloner.enabled = true;
            FakeNitro.enabled = true;
          };
          cloud = {
            authenticated = false;
            settingsSync = false;
          };
        };
      };
    };

    home.packages = with pkgs; [
      nerd-fonts.symbols-only
      fd
      btop
      tealdeer
    ];
  };
}
