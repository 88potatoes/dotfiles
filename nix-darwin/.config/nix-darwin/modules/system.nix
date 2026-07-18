# Shared system module — imported by flake.nix for each machine configuration.
# Parameters:
#   username              - macOS user account name
#   nixpkgs-unstable      - flake input for unstable nixpkgs
#   homeManagerUserConfig - pre-evaluated home-manager user config attrset
{ username, nixpkgs-unstable, homeManagerUserConfig }:
{ config, pkgs, inputs, ... }: {
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  # Expose nixpkgs-unstable as pkgs.unstable
  nixpkgs.overlays = [
    (final: prev: {
      unstable = nixpkgs-unstable.legacyPackages.${prev.system};
    })
  ];

  # ── Nix settings ──────────────────────────────────
  nix.enable = false;
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
    gh
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
    pkgs.unstable.bob-nvim

    # file mgmt / tmux
    yazi
    zellij
    lazygit

    # nix utils
    nix-output-monitor
    nix-tree
    comma

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

    starship
    fzf
    zoxide
    mise
    zsh-autosuggestions
    zsh-syntax-highlighting
    stow
    go-task
    awscli2

    # editor tooling
    nodePackages.eslint_d

    # languages
    openjdk
    lazygit
    gitleaks
    pre-commit
    just
    postgresql
  ];

  # ── Homebrew (casks only – GUI apps not in nixpkgs) ──
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    brews = [
      "worktrunk"
    ];
    casks = [
      "karabiner-elements"
      "font-iosevka"
      "bitwarden"
      "ghostty"
      "1password"
      "raycast"
      "jetbrains-toolbox"
      "whatsapp"
      "google-gemini"
      "meetingbar"
      "surfshark"
      "notion"
      "opensuperwhisper"
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
      FXPreferredViewStyle = "Nlsv";
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
  users.users.${username}.home = "/Users/${username}";

  # ── Shell ──────────────────────────────────────────
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # ── Environment ─────────────────────────────────────
  environment.variables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };
  programs.zsh.interactiveShellInit = ''
    export PATH="$HOME/.npm-global/bin:$PATH"
  '';

  # ── Services ───────────────────────────────────────
  services.karabiner-elements.enable = false;

  # ── Sudo ───────────────────────────────────────────
  security.sudo.extraConfig = ''
    # Allow darwin-rebuild without password
    %admin ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  # ── State version ──────────────────────────────────
  system.stateVersion = 5;

  # ── Home Manager ───────────────────────────────────
  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = homeManagerUserConfig;
  };
}