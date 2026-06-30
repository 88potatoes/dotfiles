{
  description = "Eric's Darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, nix-homebrew }@inputs: {
    darwinConfigurations."Mac" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;

          # ── Nix settings ──────────────────────────────────
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
          };

          # ── System packages (CLI + GUI) ─────────────────────
          environment.systemPackages = with pkgs; [
            # shell / core
            coreutils
            curl
            wget
            git
            gnugrep
            gnused
            jq
            yq
            ripgrep
            fd

            # monitoring
            htop
            btop

            # editors
            neovim

            # nix utils
            nix-output-monitor  # nom, pretty nix build output
            nix-tree
            comma             # ,  – run any package by name

            # GUI apps
            alacritty
            firefox
            spotify
            vscode
            obsidian
            signal-desktop
            maccy
            iina
          ];

          # ── Homebrew integration ────────────────────────────
          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              upgrade = true;
              cleanup = "zap";  # remove casks/brews not listed here
            };

            # Already installed via your current Brewfile
            brews = [
              "stow"
              "neovim"
              "yazi"
              "zellij"
              "zoxide"
              "zsh-autosuggestions"
              "zsh-syntax-highlighting"
              "starship"
              "fzf"
            ];

            casks = [
              "brave-browser"
              "ghostty"
              "1password"
              "jetbrains-toolbox"
              "raycast"
            ];
          };

          # ── macOS system defaults ─────────────────────────
          system.defaults = {
            dock = {
              autohide = true;
              autohide-delay = 0.0;
              autohide-time-modifier = 0.3;
              minimize-to-application = true;
              show-recents = false;
              static-only = true;
            };

            finder = {
              AppleShowAllExtensions = true;
              AppleShowAllFiles = false;
              ShowPathbar = true;
              ShowStatusBar = true;
              FXPreferredViewStyle = "Nlsv"; # list view
            };

            NSGlobalDomain = {
              AppleShowAllExtensions = true;
              AppleShowScrollBars = "Always";
              NSAutomaticCapitalizationEnabled = false;
              NSAutomaticDashSubstitutionEnabled = false;
              NSAutomaticPeriodSubstitutionEnabled = false;
              NSAutomaticQuoteSubstitutionEnabled = false;
              NSAutomaticSpellingCorrectionEnabled = false;
              NSNavPanelExpandedStateForSaveMode = true;
              NSNavPanelExpandedStateForSaveMode2 = true;
            };

            trackpad = {
              Clicking = true;
              TrackpadThreeFingerDrag = true;
            };
          };

          # ── Shell ──────────────────────────────────────────
          programs.zsh.enable = true;
          environment.shells = [ pkgs.zsh ];
          # Don't set default shell – macOS manages that.
          # If you want nix-managed zsh: sudo chsh -s /run/current-system/sw/bin/zsh

          # ── Services ───────────────────────────────────────
          services.nix-daemon.enable = true;

          # ── State version ──────────────────────────────────
          system.stateVersion = 5; # nix-darwin version, not macOS
        })
      ];
    };
  };
}
