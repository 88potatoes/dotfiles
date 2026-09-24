# Shared home-manager config — imported by flake.nix, parameterized by username.
# Paths are relative to this file (modules/), so dotfiles are at ../home/.
username: { pkgs, lib, ... }: {
  home.stateVersion = "24.11";
  home.username = username;
  home.packages = with pkgs; [
    # User-level packages go here (not system-wide)
  ];

  xdg.configFile = {
    "yazi/yazi.toml".source = ../home/yazi/yazi.toml;
    "yazi/theme.toml".source = ../home/yazi/theme.toml;

    "btop/btop.conf".source = ../home/btop/btop.conf;

    "kitty/kitty.conf".source = ../home/kitty/kitty.conf;

    "lazygit/config.yml".source = ../home/lazygit/config.yml;

    "zellij/config.kdl".source = ../home/zellij/config.kdl;
    "zellij/layouts/blog.kdl".source = ../home/zellij/layouts/blog.kdl;
    "zellij/open_blog" = {
      source = ../home/zellij/open_blog;
      executable = true;
    };

    "ghostty/config".source = ../home/ghostty/config;

    "karabiner/karabiner.json".source = ../home/karabiner/karabiner.json;

    "cmux/cmux.json".source = ../home/cmux/cmux.json;

    "git/ignore".text = ''
      .pi-subagents/*
    '';
  };

  home.file = {
    ".zshrc".source = ../home/zsh/.zshrc;
  };

  programs.brave = {
    enable = true;
    extensions = [
      { id = "amddgdnlkmohapieeekfknakgdnpbleb"; }  # xTab
      { id = "nngceckbapebfimnlniiiahkandclblb"; }  # Bitwarden
      { id = "nffaoalbilbmmfgbnbgppjihopabppdk"; }  # Video Speed Controller
    ];
  };

  programs.mise = {
    enable = true;
    globalConfig = {
      tools = {
        node = "24.16.0";
      };
    };
  };

  # Auto-install mise tools after config change
  home.activation.installMiseTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.mise}/bin/mise install
  '';

  # Keep corepack pnpm/pnpx shims available for every mise-installed Node.
  home.activation.enableCorepackPnpmForMiseNodes = lib.hm.dag.entryAfter [ "installMiseTools" ] ''
    for node_dir in "$HOME/.local/share/mise/installs/node"/*; do
      if [ -d "$node_dir" ] && [ ! -L "$node_dir" ] && [ -f "$node_dir/lib/node_modules/corepack/dist/pnpm.js" ]; then
        run ln -sf ../lib/node_modules/corepack/dist/pnpm.js "$node_dir/bin/pnpm"
        run ln -sf ../lib/node_modules/corepack/dist/pnpx.js "$node_dir/bin/pnpx"
      fi
    done
    run ${pkgs.mise}/bin/mise reshim node
  '';

  # Auto-install neovim 0.11.3 via bob-nvim.
  # Skip `bob use` — it just copies a convenience proxy (fails during activation).
  # nvim is already on PATH via ~/.local/share/bob/nvim-bin/.
  home.activation.installBobNvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.unstable.bob-nvim}/bin/bob install 0.11.3
  '';

  # Register Rectangle as a login item on macOS startup
  home.activation.registerRectangleLoginItem = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "/Applications/Rectangle.app" ]; then
      /usr/bin/osascript -e 'tell application "System Events" to get name of every login item' 2>/dev/null | grep -q "Rectangle" || \
      /usr/bin/osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Rectangle.app", hidden:false}' >/dev/null 2>&1 || true
    fi
  '';

  # Register Tinycast as a login item on macOS startup (and remove Raycast)
  home.activation.registerTinycastLoginItem = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "/Applications/Tinycast.app" ]; then
      /usr/bin/osascript -e 'tell application "System Events" to get name of every login item' 2>/dev/null | grep -q "Tinycast" || \
      /usr/bin/osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Tinycast.app", hidden:false}' >/dev/null 2>&1 || true
    fi
    /usr/bin/osascript -e 'tell application "System Events" to delete (every login item whose name is "Raycast")' >/dev/null 2>&1 || true
  '';

  # Dotfile-driven Snippets, Notes, and Extensions directories for Tinycast
  # Note: The parent directories must be real directories (not symlinks),
  # because Swift's FileManager.contentsOfDirectory fails with ENOTDIR on symlinked folders.
  home.activation.setupTinycast = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    APP_DIR="$HOME/Library/Application Support/com.tinycast.app"
    mkdir -p "$APP_DIR"

    # Extensions
    EXT_DIR="$APP_DIR/extensions"
    if [ -L "$EXT_DIR" ]; then
      run rm -f "$EXT_DIR"
    fi
    mkdir -p "$EXT_DIR"
    if [ -d "$HOME/dotfiles/nix-darwin/.config/nix-darwin/home/tinycast/extensions" ]; then
      for item in "$HOME/dotfiles/nix-darwin/.config/nix-darwin/home/tinycast/extensions/"*; do
        if [ -d "$item" ]; then
          run ln -sfn "$item" "$EXT_DIR/$(basename "$item")"
        fi
      done
    fi

    # Snippets
    SNIP_DIR="$APP_DIR/Snippets"
    if [ -L "$SNIP_DIR" ]; then
      run rm -f "$SNIP_DIR"
    fi
    mkdir -p "$SNIP_DIR"
    if [ -d "$HOME/dotfiles/nix-darwin/.config/nix-darwin/home/tinycast/snippets" ]; then
      for item in "$HOME/dotfiles/nix-darwin/.config/nix-darwin/home/tinycast/snippets/"*; do
        if [ -f "$item" ] && [ "$(basename "$item")" != ".gitkeep" ]; then
          run ln -sfn "$item" "$SNIP_DIR/$(basename "$item")"
        fi
      done
    fi

    # Notes
    NOTES_DIR="$APP_DIR/Notes"
    if [ -L "$NOTES_DIR" ]; then
      run rm -f "$NOTES_DIR"
    fi
    mkdir -p "$NOTES_DIR"
    if [ -d "$HOME/dotfiles/nix-darwin/.config/nix-darwin/home/tinycast/notes" ]; then
      for item in "$HOME/dotfiles/nix-darwin/.config/nix-darwin/home/tinycast/notes/"*; do
        if [ -f "$item" ] && [ "$(basename "$item")" != ".gitkeep" ]; then
          run ln -sfn "$item" "$NOTES_DIR/$(basename "$item")"
        fi
      done
    fi

    # Auto-restart Tinycast if running so new extensions and configs reload
    if pgrep -x "Tinycast" >/dev/null 2>&1; then
      pkill -x "Tinycast" 2>/dev/null || true
      sleep 1
      open -a "/Applications/Tinycast.app" 2>/dev/null || true
    fi
  '';
}