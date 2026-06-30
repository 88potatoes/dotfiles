stow-all:
  stow zsh
  stow nvim
  stow zellij
  stow spotify-player
  stow ghostty
  stow btop
  stow karabiner
  stow yazi
  stow lazygit
  stow local-bin
  stow nix-darwin

install-all:
  darwin-rebuild switch --flake /Users/ericlang/dotfiles/nix-darwin/.config/nix-darwin#Mac

