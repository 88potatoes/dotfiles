import cac from 'cac';
import { CommentService } from './comments/service.ts';
import { CommentRepo } from './comments/repo.ts';
import { CommentStatus } from './comments/comments.domain.ts';
import { LineRangeType, parseLineInput } from './lib/helpers.ts';


const cli = cac('agent-comments');

const service = new CommentService({
  commentsRepo: CommentRepo.instance
});

cli.command("add <file> <lines> <message>", "Add a comment").action(action(async (file, lines, message) => {
  const lineRange = parseLineInput(lines);

  if (lineRange.type === LineRangeType.Single) {
    const comment = await service.addComment({ file, startLine: lineRange.line, endLine: lineRange.line, message })
    console.log(`Added ${comment.id.slice(0, 8)} at ${file}:${lineRange.line}`);
  } else {
    const comment = await service.addComment({ file, startLine: lineRange.startLine, endLine: lineRange.endLine, message })
    console.log(`Added ${comment.id.slice(0, 8)} at ${file}:${lineRange.startLine}-${lineRange.endLine}`);
  }
}));

cli.command("delete <comment_id>", "Delete a comment").action(action(async (commentId) => {
  await service.deleteComment(commentId)
  console.log(`Deleted ${commentId.slice(0, 8)}`);
}));

cli.command("resolve <comment_id>", "Resolve a comment").action(action(async (commentId) => {
  await service.resolveComment(commentId)
  console.log(`Resolved ${commentId.slice(0, 8)}`);
}));

cli.command("unresolve <comment_id>", "Unresolve a comment").action(action(async (commentId) => {
  await service.unresolveComment(commentId)
  console.log(`Unresolved ${commentId.slice(0, 8)}`);
}));

import { formatDefault, formatJson, formatTable, wordWrap } from './lib/format.ts';
export { formatDefault, formatJson, formatTable, wordWrap };
cli.command("get", "Get comments")
  .option("-f, --file <file>", "Filter by file path")
  .option("-s, --status <status>", "Filter by status: resolved, active, or all (default: active)")
  .option("--view <view>", "Output format: default, table, or json", { default: "default" })
  .action(action(async (options) => {
    const filter: { file?: string; status?: CommentStatus } = { status: CommentStatus.Active };
    if (options.file) filter.file = options.file;
    if (options.status === "resolved") filter.status = CommentStatus.Resolved;
    else if (options.status === "active") filter.status = CommentStatus.Active;
    else if (options.status === "all") filter.status = undefined as any;
    else if (options.status) throw new Error(`Invalid status: "${options.status}". Use resolved, active, or all.`);

    const comments = await service.getAllComments(filter)

    if (options.view === "json") {
      console.log(formatJson(comments))
    } else if (options.view === "table") {
      console.log(formatTable(comments))
    } else {
      console.log(formatDefault(comments))
    }
  }));

cli.help()
cli.version('1.0.0')

function action<T extends any[]>(handler: (...args: T) => Promise<void>) {
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

cli.addEventListener('command:*', () => {
  console.error(`Unknown command: ${cli.args.join(' ')}`)
  process.exit(1)
})

cli.parse()
