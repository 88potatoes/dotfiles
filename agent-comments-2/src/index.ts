import { Command } from 'commander';
import { CommentService } from './comments/service.ts';
import { CommentRepo } from './comments/repo.ts';
import { CommentStatus } from './comments/comments.domain.ts';
import { LineRangeType, parseLineInput } from './lib/helpers.ts';
import { formatDefault, formatJson, formatGraph, wordWrap } from './lib/format.ts';

export { formatDefault, formatJson, formatGraph, wordWrap };

const program = new Command();

const service = new CommentService({
  commentsRepo: CommentRepo.instance
});

function wrap<T extends any[]>(handler: (...args: T) => Promise<void>) {
  return async (...args: T) => {
    try {
      await handler(...args)
    } catch (e: any) {
      console.error(`
  ✖ ${e.message}
`)
      process.exit(1)
    }
  }
}

program
  .name('agent-comments')
  .version('1.0.0')
  .description('Inline comment system for code reviews')

program
  .command('add <file> <lines> <message>')
  .description('Add a comment')
  .action(wrap(async (file: string, lines: string, message: string) => {
    const lineRange = parseLineInput(lines);

    if (lineRange.type === LineRangeType.Single) {
      const comment = await service.addComment({ file, startLine: lineRange.line, endLine: lineRange.line, message })
      console.log(`Added ${comment.id.slice(0, 8)} at ${file}:${lineRange.line}`);
    } else {
      const comment = await service.addComment({ file, startLine: lineRange.startLine, endLine: lineRange.endLine, message })
      console.log(`Added ${comment.id.slice(0, 8)} at ${file}:${lineRange.startLine}-${lineRange.endLine}`);
    }
  }))

program
  .command('delete <commentId>')
  .description('Delete a comment')
  .action(wrap(async (commentId: string) => {
    await service.deleteComment(commentId)
    console.log(`Deleted ${commentId.slice(0, 8)}`);
  }))

program
  .command('resolve <commentIds...>')
  .description('Resolve one or more comments')
  .action(wrap(async (commentIds: string[]) => {
    for (const id of commentIds) {
      await service.resolveComment(id)
      console.log(`Resolved ${id.slice(0, 8)}`);
    }
  }))

program
  .command('unresolve <commentIds...>')
  .description('Unresolve one or more comments')
  .action(wrap(async (commentIds: string[]) => {
    for (const id of commentIds) {
      await service.unresolveComment(id)
      console.log(`Unresolved ${id.slice(0, 8)}`);
    }
  }))

program
  .command('clean')
  .description('Delete all resolved comments (aliases: prune, purge, clear-resolved, cleanup)')
  .action(wrap(async () => {
    const count = await service.clearResolved()
    console.log(`Cleared ${count} resolved comment${count === 1 ? '' : 's'}`)
  }))

program
  .command('get')
  .description('Get comments')
  .option('-f, --file <file>', 'Filter by file path')
  .option('-s, --status <status>', 'Filter by status: resolved, active, or all (default: active)')
  .option('--view <view>', 'Output format: default, graph, or json', 'default')
  .action(wrap(async (options) => {
    const filter: { file?: string; status?: CommentStatus } = { status: CommentStatus.Active };
    if (options.file) filter.file = options.file;
    if (options.status === "resolved") filter.status = CommentStatus.Resolved;
    else if (options.status === "active") filter.status = CommentStatus.Active;
    else if (options.status === "all") filter.status = undefined as any;
    else if (options.status) throw new Error(`Invalid status: "${options.status}". Use resolved, active, or all.`);

    const comments = await service.getAllComments(filter)

    if (options.view === "json") {
      console.log(formatJson(comments))
    } else if (options.view === "graph") {
      const highlight = !!(process.stdout.isTTY && !process.env.NO_COLOR)
      console.log(formatGraph(comments, 80, highlight))
    } else {
      console.log(formatDefault(comments))
    }
  }))

await program.parseAsync()