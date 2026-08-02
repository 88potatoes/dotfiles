# Nix rebuild + restow
#
# Usage:
#   just reload            → reads profile from ~/.config/nix-profile
#   just reload WorkMac    → override with #WorkMac

_nix_profile := trim(shell("""
  cat ~/.config/nix-profile 2>/dev/null || \
  (echo 'Error: ~/.config/nix-profile not found. Create it with your profile name (e.g. Mac or WorkMac), or pass one explicitly.' >&2 && exit 1)
"""))

reload profile=_nix_profile:
  darwin-rebuild switch --flake ~/dotfiles/nix-darwin/.config/nix-darwin#{{profile}}
  just stow-all

stow-all:
  stow local-bin
  stow pi
