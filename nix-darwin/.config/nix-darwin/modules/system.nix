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