# Full nix reload + restow
reload:
  /run/current-system/sw/bin/darwin-rebuild switch --flake /Users/ericlang/dotfiles/nix-darwin/.config/nix-darwin#Mac
  just stow-all

stow-all:
  stow local-bin

install-all:
  darwin-rebuild switch --flake /Users/ericlang/dotfiles/nix-darwin/.config/nix-darwin#Mac

