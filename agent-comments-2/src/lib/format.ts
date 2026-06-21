import { CommentEntity, CommentStatus } from '../comments/comments.domain.ts'

export function wordWrap(text: string, maxWidth: number): string[] {
  const lines: string[] = []
  for (const paragraph of text.split('\n')) {
    if (paragraph.length === 0) {
      lines.push('')
    } else {
      let remaining = paragraph
      while (remaining.length > maxWidth) {
        const segment = remaining.slice(0, maxWidth)
        const spaceIdx = segment.lastIndexOf(' ')
        if (spaceIdx > 0) {
          lines.push(remaining.slice(0, spaceIdx))
          remaining = remaining.slice(spaceIdx + 1)
        } else {
          lines.push(segment)
          remaining = remaining.slice(maxWidth)
        }
      }
      if (remaining.length > 0) {
        lines.push(remaining)
      }
    }
  }
  return lines
}

export function formatDefault(comments: CommentEntity[]): string {
  const header = 'ID|File:Line|Message|Status'
  const body = comments
    .map((c) => `${c.id}|${c.file}:${c.startLine}-${c.endLine}|${c.message}|${c.status}`)
    .join('\n')
  return body.length > 0 ? `${header}\n${body}` : ''
}

export function formatJson(comments: CommentEntity[]): string {
  return JSON.stringify({ comments }, null, 2)
}

export function formatTable(comments: CommentEntity[], messageWidth = 80): string {
  const blocks: string[] = []
  for (const c of comments) {
    const icon = c.status === 'active' ? '●' : '✓'
    const shortId = c.id.slice(0, 8)
    const linesLabel = c.startLine === c.endLine
      ? `${c.startLine}`
      : `${c.startLine}-${c.endLine}`
    const fileLine = `${c.file}:${linesLabel}`
    const header = `${icon} ${shortId}  ${fileLine}`
    const lines: string[] = [header]
    const continuationIndent = `${icon} ${shortId}  `.length
    const wrapped = wordWrap(c.message, messageWidth)
    for (const wl of wrapped) {
      lines.push(`${' '.repeat(continuationIndent)}${wl}`)
    }
    lines.push('')
    blocks.push(lines.join('\n'))
  }
  return blocks.join('\n')
}
