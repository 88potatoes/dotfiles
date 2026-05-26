import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import { Box, Text } from '@earendil-works/pi-tui';

const TIMEOUT_MS = 120_000;
const MAX_OUTPUT_CHARS = 20_000;

const trimOutput = (value: string) => {
  if (value.length <= MAX_OUTPUT_CHARS) return value;
  return `${value.slice(0, MAX_OUTPUT_CHARS)}\n\n[truncated: ${value.length - MAX_OUTPUT_CHARS} chars omitted]`;
};

export default function terminalCommandExtension(pi: ExtensionAPI) {
  pi.registerMessageRenderer('terminal-command', (message, _options, theme) => {
    const details = message.details as
      | {
          command?: string;
          cwd?: string;
          code?: number | null;
          durationMs?: number;
          stdout?: string;
          stderr?: string;
          error?: string;
        }
      | undefined;

    const command = details?.command ?? '';
    const cwd = details?.cwd ?? '';
    const code = details?.code;
    const durationMs = details?.durationMs;
    const stdout = details?.stdout ?? '';
    const stderr = details?.stderr ?? '';
    const error = details?.error;

    const status = error
      ? theme.fg('error', 'error')
      : code === 0
        ? theme.fg('success', 'exit 0')
        : theme.fg('error', `exit ${code ?? 'unknown'}`);

    const lines = [
      `${theme.fg('accent', '$')} ${command}`,
      `${theme.fg('dim', cwd)} ${status}${durationMs == null ? '' : theme.fg('dim', ` ${durationMs}ms`)}`,
    ];

    if (stdout) {
      lines.push('', theme.fg('muted', 'stdout'), stdout);
    }

    if (stderr) {
      lines.push('', theme.fg('warning', 'stderr'), stderr);
    }

    if (error) {
      lines.push('', theme.fg('error', error));
    }

    const text = lines.join('\n');
    const box = new Box(1, 1, (t) => theme.bg('customMessageBg', t));
    box.addChild(new Text(text, 0, 0));
    return box;
  });

  pi.registerCommand('t', {
    description: 'Run a terminal command without starting an agent turn',
    handler: async (args, ctx) => {
      const command = args.trim();

      if (!command) {
        ctx.ui.notify('Usage: /t <shell command>', 'warning');
        return;
      }

      const startedAt = Date.now();

      try {
        const result = await pi.exec('bash', ['-lc', command], {
          timeout: TIMEOUT_MS,
        });

        pi.sendMessage({
          customType: 'terminal-command',
          content: `$ ${command}`,
          display: true,
          details: {
            command,
            cwd: ctx.cwd,
            code: result.code,
            durationMs: Date.now() - startedAt,
            stdout: trimOutput(result.stdout ?? ''),
            stderr: trimOutput(result.stderr ?? ''),
          },
        });
      } catch (err) {
        pi.sendMessage({
          customType: 'terminal-command',
          content: `$ ${command}`,
          display: true,
          details: {
            command,
            cwd: ctx.cwd,
            durationMs: Date.now() - startedAt,
            error: err instanceof Error ? err.message : String(err),
          },
        });
      }
    },
  });
}
