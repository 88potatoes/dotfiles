{
  description = "Eric's Darwin system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager/d5f1f641b289553927b3801580598d200a501863";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, nix-homebrew, home-manager }@inputs: {
    darwinConfigurations."Mac" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        home-manager.darwinModules.home-manager
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.allowBroken = true;

          # ── Nix settings ──────────────────────────────────
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = false;
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

            # file mgmt / tmux
            yazi
            zellij
            lazygit

            # nix utils
            nix-output-monitor  # nom, pretty nix build output
            nix-tree
            comma             # ,  – run any package by name

            # GUI apps (from nixpkgs)
            alacritty
            spotify
            vscode
            obsidian
            signal-desktop
            maccy
            iina
            brave
            kitty
            rectangle

            # fonts (installed via brew)

            # Note: bitwarden, ghostty, 1password, raycast, jetbrains-toolbox, whatsapp not in nixpkgs.
            # Managed via brew casks below.

            starship
            fzf
            zoxide
            mise
            zsh-autosuggestions
            zsh-syntax-highlighting
            stow

            # languages
            nodejs
            pnpm
            openjdk
            lazygit
            gitleaks
            pre-commit
            just
          ];

          # ── Homebrew (casks only – GUI apps not in nixpkgs) ──
          homebrew = {
            enable = true;
            onActivation = {
              autoUpdate = true;
              upgrade = true;
              cleanup = "zap";
            };
            brews = [];
            casks = [
              "karabiner-elements"
              "font-iosevka"
              "bitwarden"
              "ghostty"
              "1password"
              "raycast"
              "jetbrains-toolbox"
              "whatsapp"
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

          # ── Users ─────────────────────────────────────────
          users.users.ericlang.home = "/Users/ericlang";

          # ── Shell ──────────────────────────────────────────
          programs.zsh.enable = true;
          environment.shells = [ pkgs.zsh ];

          # ── Environment ─────────────────────────────────────
          environment.variables = {
            NPM_CONFIG_PREFIX = "$HOME/.npm-global";
          };
          # Add npm global bin to PATH
          programs.zsh.interactiveShellInit = ''
            export PATH="$HOME/.npm-global/bin:$PATH"
          '';
          # Don't set default shell – macOS manages that.
          # If you want nix-managed zsh: sudo chsh -s /run/current-system/sw/bin/zsh

          # ── Services ───────────────────────────────────────
          services.nix-daemon.enable = true;
          services.karabiner-elements.enable = false;

          # ── Sudo ───────────────────────────────────────────
          security.sudo.extraConfig = ''
            # Allow darwin-rebuild without password
            %admin ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
          '';

          # ── State version ──────────────────────────────────
          system.stateVersion = 5; # nix-darwin version, not macOS

          # ── Home Manager (user-level config) ──────────────
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.ericlang = { pkgs, ... }: {
              home.stateVersion = "24.11";
              home.username = "ericlang";
              home.packages = with pkgs; [
                # User-level packages go here (not system-wide)
              ];

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
            };
          };
        })
      ];
    };
  };
}
