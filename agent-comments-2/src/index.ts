import cac from 'cac';
import { CommentService } from './comments/service.ts';
import { CommentRepo } from './comments/repo.ts';
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
//   agent-comments get [resolved|unresolved|<file>]

cli.command("add <file> <lines> <message>", "Add a comment").action(async (file, lines, message) => {
  const lineRange = parseLineInput(lines);

  if (lineRange.type === LineRangeType.Single) {
    service.addComment({ file, startLine: lineRange.line, endLine: lineRange.line, message })
  } else {
    service.addComment({ file, startLine: lineRange.startLine, endLine: lineRange.endLine, message })
  }
});

cli.command("delete <comment_id>", "Delete a comment").action(async (commentId) => {
  service.deleteComment(commentId)
});

cli.command("resolve <comment_id>", "Resolve a comment").action(async (commentId) => {
  service.resolveComment(commentId)
});

cli.command("unresolve <comment_id>", "Unresolve a comment").action(async (commentId) => {
  service.unresolveComment(commentId)
});

cli.command("get [resolved|unresolved|<file>]", "Get comments").action(async (filter) => {
  if (filter === "resolved") {
    service.getAllComments().then(comments => console.log(JSON.stringify(comments, null, 2)))
  } else if (filter === "unresolved" || filter === "active") {
    service.getAllComments().then(comments => console.log(JSON.stringify(comments, null, 2)))
  } else if (filter) {
    // Maybe it's a file path
    service.getAllComments().then(comments => console.log(JSON.stringify(comments, null, 2)))
  } else {
    service.getAllComments().then(comments => console.log(JSON.stringify(comments, null, 2)))
  }
});
