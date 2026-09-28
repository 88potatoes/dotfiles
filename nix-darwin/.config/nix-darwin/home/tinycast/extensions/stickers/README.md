# Stickers

Save images and GIFs from anywhere, then paste them anywhere.

## Commands

- **Save Sticker from Clipboard** (`save-sticker`) — saves the image on your clipboard to your stickers folder. Handles:
  - an image file copied in Finder
  - an image URL in the clipboard (e.g. from "Copy Image Address")
  - anything else: falls back to the newest image in Tinycast's own clipboard history (covers "Copy Image" in browsers — Tinycast's clipboard API is text-only)
  - Every sticker is center-cropped square, resized to 256×256 and saved as a JPEG (~85 quality). GIFs become static images; for animated stickers keep the original file instead.
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
