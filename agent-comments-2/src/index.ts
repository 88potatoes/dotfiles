import cac from 'cac';
import { CommentService } from './comments/service.ts';
import { CommentRepo } from './comments/repo.ts';
import { CommentStatus } from './comments/comments.domain.ts';
import { LineRangeType, parseLineInput } from './lib/helpers.ts';


const cli = cac('agent-comments');

const service = new CommentService({
  commentsRepo: CommentRepo.instance
});

// Usage:
//   agent-comments add <file> <lines> <message>
//   agent-comments add <file> -l <lines> -m <message>
//   agent-comments delete <comment_id>
//   agent-comments resolve <comment_id>
//   agent-comments unresolve <comment_id>
//   agent-comments get [-f <file>] [-s <resolved|unresolved|active>]

cli.command("add <file> <lines> <message>", "Add a comment").action(async (file, lines, message) => {
  const lineRange = parseLineInput(lines);

  if (lineRange.type === LineRangeType.Single) {
    const comment = await service.addComment({ file, startLine: lineRange.line, endLine: lineRange.line, message })
    console.log(`Added ${comment.id.slice(0, 8)} at ${file}:${lineRange.line}`);
  } else {
    service.addComment({ file, startLine: lineRange.startLine, endLine: lineRange.endLine, message })
    const comment = await service.getAllComments({ file }).then(comments => comments[0])
    console.log(`Added ${comment.id.slice(0, 8)} at ${file}:${lineRange.startLine}-${lineRange.endLine}`);
  }

});

cli.command("delete <comment_id>", "Delete a comment").action(async (commentId) => {
  service.deleteComment(commentId)
  console.log(`Deleted ${commentId.slice(0, 8)}`);
});

cli.command("resolve <comment_id>", "Resolve a comment").action(async (commentId) => {
  service.resolveComment(commentId)
  console.log(`Resolved ${commentId.slice(0, 8)}`);
});

cli.command("unresolve <comment_id>", "Unresolve a comment").action(async (commentId) => {
  service.unresolveComment(commentId)
  console.log(`Unresolved ${commentId.slice(0, 8)}`);
});

cli.command("get", "Get comments").option("-f, --file <file>", "Filter by file path").option("-s, --status <status>", "Filter by status (resolved|active)").action(async (options) => {
  const filter: { file?: string; status?: CommentStatus } = {};
  if (options.file) filter.file = options.file;
  if (options.status === "resolved") filter.status = CommentStatus.Resolved;
  else if (options.status === "active") filter.status = CommentStatus.Active;
  else if (options.status) throw new Error(`Invalid status: "${options.status}". Use resolved, unresolved, or active.`);

  service.getAllComments(filter).then(comments => console.log(comments.map((comment) => `${comment.id}|${comment.file}:${comment.startLine}-${comment.endLine}|${comment.message}|${comment.status}`).join('\n')));
});
