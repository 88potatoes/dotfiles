# Shared system module — imported by flake.nix for each machine configuration.
# Parameters:
#   username              - macOS user account name
#   nixpkgs-unstable      - flake input for unstable nixpkgs
#   homeManagerUserConfig - pre-evaluated home-manager user config attrset
{ username, nixpkgs-unstable, homeManagerUserConfig }:
{ config, pkgs, inputs, ... }:
let
  cliPkgs = import ./packages/cli.nix pkgs;
  guiPkgs = import ./packages/gui.nix pkgs;
in {
  imports = [
    ./homebrew.nix
    ./macos-defaults.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  # Expose nixpkgs-unstable as pkgs.unstable and provide lixPackageSets
  nixpkgs.overlays = [
    (final: prev: {
      unstable = nixpkgs-unstable.legacyPackages.${prev.system};
      lixPackageSets = prev.lixPackageSets or nixpkgs-unstable.legacyPackages.${prev.system}.lixPackageSets;
    })
    (final: prev: {
      inherit (prev.lixPackageSets.stable)
        nixpkgs-review
        nix-eval-jobs
        nix-fast-build
        colmena;
    })
  ];

  # ── Nix settings ──────────────────────────────────
  nix.enable = true;
  nix.package = pkgs.lixPackageSets.stable.lix;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-deprecated-features = [ "or-as-identifier" "rec-set-dynamic-attrs" ];
    auto-optimise-store = false;
  };

  # ── System packages (CLI + GUI) ─────────────────────
  environment.systemPackages = cliPkgs ++ guiPkgs;

  # ── Users ─────────────────────────────────────────
  users.users.${username}.home = "/Users/${username}";

  # ── Shell ──────────────────────────────────────────
  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  # ── Environment ─────────────────────────────────────
  environment.variables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  # Add Homebrew to system path (nix-darwin overrides default path_helper)
  environment.systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];

  programs.zsh.interactiveShellInit = ''
    export PATH="$HOME/.npm-global/bin:$PATH"
  '';

  # ── Services ───────────────────────────────────────
  services.karabiner-elements.enable = false;

  # ── Sudo & PAM ─────────────────────────────────────
  security.pam.enableSudoTouchIdAuth = true;
  security.sudo.extraConfig = ''
    # Allow darwin-rebuild without password
    %admin ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  # ── Activation Scripts ─────────────────────────────
  # Disable strict /etc checks that abort on unmanaged zshrc/zprofile
  system.activationScripts.etcChecks.text = pkgs.lib.mkForce "";

  # Automatically back up any conflicting /etc files before linking
  system.activationScripts.preActivation.text = ''
    for f in /etc/zshrc /etc/zprofile; do
      if [ -e "$f" ] && [ ! -L "$f" ]; then
        echo "Backing up unmanaged $f to $f.bak"
        mv -f "$f" "$f.bak"
      fi
    done
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