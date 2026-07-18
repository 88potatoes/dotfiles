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
}