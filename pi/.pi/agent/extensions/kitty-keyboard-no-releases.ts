import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// Pi asks terminals to report key releases so it can support richer key
// bindings. Ghostty currently forwards a modifier-key release (for example,
// releasing C after Cmd+C) to its `scroll-to-bottom=keystroke` action. That
// makes copying text jump the terminal viewport to the newest output.
//
// Keep Kitty's disambiguation and alternate-key reporting, but turn off event
// type reporting (flag 2), which is the part that enables key-release events.
const KITTY_PROTOCOL_WITHOUT_RELEASES = "\x1b[>5u"; // flags 1 + 4
const REAPPLY_DELAY_MS = 250;

export default function (pi: ExtensionAPI) {
  let reapplyTimer: ReturnType<typeof setTimeout> | undefined;

  const disableReleaseReporting = () => {
    if (process.stdout.isTTY) {
      process.stdout.write(KITTY_PROTOCOL_WITHOUT_RELEASES);
    }
  };

  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui" || !process.stdout.isTTY) return;

    // Apply immediately for already-negotiated terminals, then once more
    // after Pi's startup Kitty-protocol negotiation has settled.
    disableReleaseReporting();
    reapplyTimer = setTimeout(disableReleaseReporting, REAPPLY_DELAY_MS);
  });

  pi.on("session_shutdown", () => {
    if (reapplyTimer) {
      clearTimeout(reapplyTimer);
      reapplyTimer = undefined;
    }
  });
}
