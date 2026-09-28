# Stickers

Save images and GIFs from anywhere, then paste them anywhere.

## Commands

- **Save Sticker from Clipboard** (`save-sticker`) — saves the image on your clipboard to your stickers folder. Handles:
  - an image file copied in Finder (copied, not moved)
  - an image copied with "Copy Image" in a browser
  - an image URL in the clipboard (e.g. from "Copy Image Address")
  - Format is detected from magic bytes, so GIFs stay GIFs.
- **Stickers** (`stickers`) — grid browser for your stickers. Paste, copy, show in Finder, or delete (to Trash) each one, and save straight from the clipboard from inside the grid.

Stickers are plain files in `~/Pictures/Stickers` (changeable via the "Stickers Folder" preference), so Finder/QuickLook work on them too.

## Daily flow

1. Give "Save Sticker from Clipboard" a hotkey in Tinycast settings (e.g. ⌥⇧S).
2. Right-click any image → Copy Image → press the hotkey. Saved.
3. Tinycast → Stickers → pick one → Paste (⌘⌥P) wherever you want.

## Install notes

- Lives in dotfiles at `nix-darwin/.config/nix-darwin/home/tinycast/extensions/stickers`.
- The `setupTinycast` home-manager activation symlinks it into
  `~/Library/Application Support/com.tinycast.app/extensions/` and restarts Tinycast.
- Plain CommonJS, no build step (same as `tinycast-utils`).
