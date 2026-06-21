import { describe, it, expect } from 'vitest'
import { wordWrap, formatDefault, formatJson, formatTable } from '../src/lib/format.ts'
import { CommentStatus } from '../src/comments/comments.domain.ts'

const active = CommentStatus.Active
const resolved = CommentStatus.Resolved

const sampleComments = [
  { id: '550e8400-e29b-41d4-a716-446655440000', file: 'src/foo.ts', startLine: 1, endLine: 5, message: 'fix this', status: active, createdAt: '', updatedAt: '' },
  { id: '660e8400-e29b-41d4-a716-446655440001', file: 'src/bar.ts', startLine: 10, endLine: 10, message: 'done', status: resolved, createdAt: '', updatedAt: '' },
  { id: '770e8400-e29b-41d4-a716-446655440002', file: 'src/foo.ts', startLine: 20, endLine: 22, message: 'a very long message that should wrap at eighty characters when displayed in the table view format', status: active, createdAt: '', updatedAt: '' },
]

// ── wordWrap ───────────────────────────────────────────────────────────

describe('wordWrap', () => {
  it('returns empty array for empty string', () => {
    expect(wordWrap('', 80)).toEqual([''])
  })

  it('returns single line for short text', () => {
    expect(wordWrap('hello world', 80)).toEqual(['hello world'])
  })

  it('wraps at word boundary', () => {
    const result = wordWrap('hello beautiful world', 10)
    expect(result).toEqual(['hello', 'beautiful', 'world'])
  })

  it('hard-breaks when no space found', () => {
    const result = wordWrap('abcdefghijklmnop', 5)
    expect(result).toEqual(['abcde', 'fghij', 'klmno', 'p'])
  })

  it('preserves paragraph breaks', () => {
    const result = wordWrap('hello\n\nworld', 80)
    expect(result).toEqual(['hello', '', 'world'])
  })
})

// ── formatDefault ──────────────────────────────────────────────────────

describe('formatDefault', () => {
  it('formats comments as pipe-delimited lines', () => {
    const output = formatDefault(sampleComments)
    const lines = output.split('\n')
    expect(lines).toHaveLength(3)
    expect(lines[0]).toBe('550e8400-e29b-41d4-a716-446655440000|src/foo.ts:1-5|fix this|active')
    expect(lines[1]).toBe('660e8400-e29b-41d4-a716-446655440001|src/bar.ts:10-10|done|resolved')
  })

  it('returns empty string for no comments', () => {
    expect(formatDefault([])).toBe('')
  })
})

// ── formatJson ─────────────────────────────────────────────────────────

describe('formatJson', () => {
  it('outputs JSON with comments array', () => {
    const output = formatJson(sampleComments)
    const parsed = JSON.parse(output)
    expect(parsed.comments).toHaveLength(3)
    expect(parsed.comments[0].file).toBe('src/foo.ts')
  })

  it('includes all fields', () => {
    const output = formatJson(sampleComments)
    const parsed = JSON.parse(output)
    expect(parsed.comments[0]).toMatchObject({
      id: expect.stringContaining('550e'),
      file: 'src/foo.ts',
      startLine: 1,
      endLine: 5,
      message: 'fix this',
      status: 'active',
    })
  })
})

// ── formatTable ────────────────────────────────────────────────────────

describe('formatTable', () => {
  it('shows icon and short id', () => {
    const output = formatTable(sampleComments, 80)
    expect(output).toContain('● 550e8400')
    expect(output).toContain('✓ 660e8400')
  })

  it('shows file:lines on header line', () => {
    const output = formatTable(sampleComments, 80)
    expect(output).toContain('● 550e8400  src/foo.ts:1-5')
    expect(output).toContain('✓ 660e8400  src/bar.ts:10')
  })

  it('wraps long messages', () => {
    const output = formatTable(sampleComments, 80)
    const longSection = output.split('770e8400')[1]
    expect(longSection).toBeTruthy()
    const lines = longSection.trim().split('\n')
    expect(lines.length).toBeGreaterThan(1)
  })

  it('separates comments with blank line', () => {
    const output = formatTable(sampleComments, 80)
    const sections = output.split('\n\n')
    expect(sections).toHaveLength(3)
  })

  it('handles empty list', () => {
    expect(formatTable([], 80)).toBe('')
  })
})