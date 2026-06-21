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

cli.command("get", "Get comments").option("-f, --file <file>", "Filter by file path").option("-s, --status <status>", "Filter by status (resolved|active)").action(action(async (options) => {
  const filter: { file?: string; status?: CommentStatus } = {};
  if (options.file) filter.file = options.file;
  if (options.status === "resolved") filter.status = CommentStatus.Resolved;
  else if (options.status === "active") filter.status = CommentStatus.Active;
  else if (options.status) throw new Error(`Invalid status: "${options.status}". Use resolved, unresolved, or active.`);

  const comments = await service.getAllComments(filter)
  console.log(comments.map((comment) => `${comment.id}|${comment.file}:${comment.startLine}-${comment.endLine}|${comment.message}|${comment.status}`).join('\n'))
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

try {
  cli.parse()
} catch (e) {
  if ((e as any)?.name === 'CACError') {
    console.error(`
  ✖ ${e.message}
`)
    if (cli.matchedCommand) cli.matchedCommand.outputHelp()
    process.exit(1)
  }
  throw e
}
