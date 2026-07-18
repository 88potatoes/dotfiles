{
  description = "Eric's Darwin system (multi-machine)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/d5f1f641b289553927b3801580598d200a501863";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, nix-homebrew, home-manager }@inputs:
  let
    # ── Shared home-manager config (parameterized by username) ──
    sharedHomeManagerConfig = username: { pkgs, lib, ... }: {
      home.stateVersion = "24.11";
      home.username = username;
      home.packages = with pkgs; [
        # User-level packages go here (not system-wide)
      ];

      xdg.configFile = {
        "yazi/yazi.toml".source = ./home/yazi/yazi.toml;
        "yazi/theme.toml".source = ./home/yazi/theme.toml;

        "btop/btop.conf".source = ./home/btop/btop.conf;

        "kitty/kitty.conf".source = ./home/kitty/kitty.conf;

        "lazygit/config.yml".source = ./home/lazygit/config.yml;

        "zellij/config.kdl".source = ./home/zellij/config.kdl;
        "zellij/layouts/blog.kdl".source = ./home/zellij/layouts/blog.kdl;
        "zellij/open_blog" = {
          source = ./home/zellij/open_blog;
          executable = true;
        };

        "ghostty/config".source = ./home/ghostty/config;

        "karabiner/karabiner.json".source = ./home/karabiner/karabiner.json;

        "cmux/cmux.json".source = ./home/cmux/cmux.json;
      };

      home.file = {
        ".zshrc".source = ./home/zsh/.zshrc;
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

      # Auto-install neovim 0.11.3 via bob-nvim
      home.activation.installBobNvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.unstable.bob-nvim}/bin/bob install 0.11.3
        run ${pkgs.unstable.bob-nvim}/bin/bob use 0.11.3
      '';
    };

    # ── Helper: build a darwinConfiguration for a given username ──
    mkDarwinConfig = username:
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          (import ./modules/system.nix {
            inherit username nixpkgs-unstable;
            homeManagerUserConfig = (sharedHomeManagerConfig username);
          })
        ];
      };

  in {
    # ── Machine-specific configurations ───────────────────────
    darwinConfigurations = {
      "Mac"     = mkDarwinConfig "ericlang";   # personal laptop
      "WorkMac" = mkDarwinConfig "changeme";   # work laptop — update to your work username
    };
  };
}