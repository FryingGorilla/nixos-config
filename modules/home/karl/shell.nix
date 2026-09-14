{ ... }:

{
  flake.homeModules.karl-shell = { config, lib, ... }: {
    # Keep history inside a preserved directory (zsh may replace history files).
    home.activation.migrateZshHistory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      history_dir="${config.xdg.dataHome}/zsh"
      if [ ! -e "$history_dir/history" ]; then
        run mkdir -p "$history_dir"
        if [ -s "${config.xdg.configHome}/zsh/.zsh_history" ]; then
          run cp "${config.xdg.configHome}/zsh/.zsh_history" "$history_dir/history"
        elif [ -s "${config.home.homeDirectory}/.zsh_history" ]; then
          run cp "${config.home.homeDirectory}/.zsh_history" "$history_dir/history"
        fi
      fi
    '';

    programs.oh-my-posh = {
      enable = true;
      enableZshIntegration = true;
      useTheme = "atomic";
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    programs.bat.enable = true;

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      defaultKeymap = "viins";
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      history = {
        path = "${config.xdg.dataHome}/zsh/history";
        size = 100000;
        save = 100000;
        append = true;
        share = true;
        extended = true;
        ignoreSpace = true;
        ignoreDups = true;
        findNoDups = true;
        expireDuplicatesFirst = true;
      };

      historySubstringSearch = {
        enable = true;
        searchUpKey = [ "^[[A" "^[OA" ];
        searchDownKey = [ "^[[B" "^[OB" ];
      };

      setOptions = [
        "AUTO_PUSHD" # Keep visited directories in the directory stack.
        "PUSHD_IGNORE_DUPS"
        "PUSHD_SILENT"
        "INTERACTIVE_COMMENTS"
        "NO_BEEP"
        "HIST_REDUCE_BLANKS"
      ];

      shellAliases = {
        sudo = "sudo ";
        cat = "bat --paging=never";
        top = "btop";
        htop = "btop";
        tree = "eza --tree";
        ff = "fd";
        z = "cd";
        zi = "cdi";
        rebuild = "sudo nixos-rebuild switch --flake ~/.config/nixos#$(hostname) --accept-flake-config";
        update = "nix flake update --flake path:~/.config/nixos && rebuild";
      };

      initContent = ''
        # Select completions with the arrow keys and match either letter case.
        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:descriptions' format '%B%d%b'
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' squeeze-slashes true

        # Word movement/deletion, plus common terminal Home/End/Delete codes.
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word
        bindkey '^[[H' beginning-of-line
        bindkey '^[OH' beginning-of-line
        bindkey '^[[1~' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[OF' end-of-line
        bindkey '^[[4~' end-of-line
        bindkey '^[[3~' delete-char
        bindkey '^[[Z' reverse-menu-complete
      '';
    };
  };
}
