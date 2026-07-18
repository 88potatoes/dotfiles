# Full nix reload + restow
# Usage: just reload           → rebuilds #Mac (personal laptop)
#        just reload WorkMac   → rebuilds #WorkMac (work laptop)
reload target="Mac":
  darwin-rebuild switch --flake ~/dotfiles/nix-darwin/.config/nix-darwin#{{target}}
  just stow-all

stow-all:
  stow local-bin

install-all target="Mac":
  darwin-rebuild switch --flake ~/dotfiles/nix-darwin/.config/nix-darwin#{{target}}