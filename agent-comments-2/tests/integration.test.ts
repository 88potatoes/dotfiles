import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { execFileSync } from 'child_process'
import { mkdtempSync, rmSync, mkdirSync } from 'fs'
import { join } from 'path'

// Hardcode project root to avoid vitest import.meta.url issues
const projectRoot = '/Users/ericlang/dotfiles/agent-comments-2'
const TSX = join(projectRoot, 'node_modules', '.bin', 'tsx')
const CLI = join(projectRoot, 'src/index.ts')

let tmpDir: string
let repoDir: string

beforeAll(() => {
  tmpDir = mkdtempSync('/tmp/ac-integration-')
  repoDir = join(tmpDir, 'test-repo')
  mkdirSync(repoDir, { recursive: true })
  execFileSync('git', ['init'], { cwd: repoDir, stdio: 'pipe' })
})

afterAll(() => {
  rmSync(tmpDir, { recursive: true, force: true })
})

function tsx(...args: string[]): string {
  const result = execFileSync(TSX, [CLI, ...args], {
    cwd: repoDir,
    encoding: 'utf-8',
    timeout: 10000,
  })
  return result.trim()
}

describe('agent-comments integration', () => {
  it('adds a comment and lists it', () => {
    const addOut = tsx('add', 'src/main.ts', '10', 'fix the bug')
    expect(addOut).toMatch(/^Added [a-f0-9]{8} at src\/main\.ts:10$/)

    const listOut = tsx('get')
    expect(listOut).toContain('fix the bug')
    expect(listOut).toContain('active')
  })

  it('resolves a comment', () => {
    tsx('add', 'src/other.ts', '5', 'wip')
    const all = tsx('get', '-s', 'all')
    const resolvedLine = all.split('\n').find((l: string) => l.includes('wip'))
    expect(resolvedLine).toBeTruthy()
    const shortId = resolvedLine!.split('|')[0].slice(0, 8)
    const resOut = tsx('resolve', shortId)
    expect(resOut).toContain('Resolved')

    const active = tsx('get')
    expect(active).not.toContain('wip')
    expect(active).toContain('fix the bug')

    const all2 = tsx('get', '-s', 'all')
    expect(all2).toContain('wip')
  })

  it('supports json view', () => {
    const out = tsx('get', '--view', 'json')
    const parsed = JSON.parse(out)
    expect(parsed.comments).toBeInstanceOf(Array)
  })

  it('supports table view', () => {
    const out = tsx('get', '--view', 'table', '-s', 'all')
    expect(out).toMatch(/● [a-f0-9]{8}/)
  })

  it('deletes a comment', () => {
    const all = tsx('get', '-s', 'all')
    const firstLine = all.split('\n')[0]
    const shortId = firstLine.split('|')[0].slice(0, 8)
    tsx('delete', shortId)
    const after = tsx('get', '-s', 'all')
    expect(after).not.toContain(shortId)
  })
})