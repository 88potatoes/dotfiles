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

    const linesWithoutSpacer = this.countLines(this.tui, width);
    const blankLines = Math.max(0, terminalRows - linesWithoutSpacer);

    return Array.from({ length: blankLines }, () => "");
  }

  invalidate(): void {}

  private countLines(component: ComponentWithChildren, width: number): number {
    if (component === this) {
      return 0;
    }

    if (Array.isArray(component.children)) {
      return component.children.reduce((count, child) => {
        return count + this.countLines(child as ComponentWithChildren, width);
      }, 0);
    }

    return component.render(width).length;
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
