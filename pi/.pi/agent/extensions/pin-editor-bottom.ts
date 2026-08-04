import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

interface Component {
  render(width: number): string[];
  invalidate(): void;
}

type ComponentWithChildren = Component & { children?: Component[] };

class BottomPinSpacer implements Component {
  private tui: ComponentWithChildren & { terminal?: { rows?: number } };

  constructor(tui: ComponentWithChildren & { terminal?: { rows?: number } }) {
    this.tui = tui;
  }

  render(width: number): string[] {
    const terminalRows = this.tui.terminal?.rows ?? 0;
    if (terminalRows <= 0) {
      return [];
    }

    // We only need to know whether the existing UI already fills the
    // viewport. Rendering the whole tree here is extremely expensive because
    // the chat container contains the entire conversation — and Pi renders
    // the tree normally immediately after this widget returns.
    //
    // Stop as soon as the viewport is full. This keeps the extra measurement
    // bounded by the terminal height instead of the conversation length.
    const linesWithoutSpacer = this.countLinesUpTo(this.tui, width, terminalRows);
    const blankLines = Math.max(0, terminalRows - linesWithoutSpacer);

    return Array.from({ length: blankLines }, () => "");
  }

  invalidate(): void {}

  private countLinesUpTo(
    component: ComponentWithChildren,
    width: number,
    limit: number,
  ): number {
    if (component === this || limit <= 0) {
      return 0;
    }

    if (Array.isArray(component.children)) {
      let count = 0;
      for (const child of component.children) {
        count += this.countLinesUpTo(child as ComponentWithChildren, width, limit - count);
        if (count >= limit) {
          return limit;
        }
      }
      return count;
    }

    return Math.min(component.render(width).length, limit);
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    ctx.ui.setWidget(
      "pin-editor-bottom",
      (tui) => new BottomPinSpacer(tui as ComponentWithChildren & { terminal?: { rows?: number } }),
      { placement: "aboveEditor" },
    );
  });
}
