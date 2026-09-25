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
  just pi-zig-patch

stow-all:
  stow local-bin
  stow pi
  stow lib
  if [ ! -e ~/.pi/agent/settings.json ]; then rm -f ~/.pi/agent/settings.json && cp ~/dotfiles/pi/.pi/agent/settings.json.template ~/.pi/agent/settings.json; fi

# Re-apply the pi-tui Zig fast path to the globally installed pi (idempotent).
# Runs on every reload so npm updates of pi are patched automatically.
pi-zig-patch:
  node ~/lib/pi-tui-zig/patch.mjs || echo 'pi-tui-zig: patch skipped (not installed?)'
