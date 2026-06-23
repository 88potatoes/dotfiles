import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { createRepoFixture } from './helpers.ts';

describe('agent-comments integration', () => {
  let fixture: ReturnType<typeof createRepoFixture>

  beforeEach(() => {
    fixture = createRepoFixture()
  })

  afterEach(() => {
    fixture.cleanup()
  })

  it('adds a comment and lists it', () => {
    const addOut = fixture.tsx('add', 'src/main.ts', '10', 'fix the bug')
    console.log('DEBUG addOut:', JSON.stringify(addOut), typeof addOut)
    expect(addOut).toMatch(/^Added [a-f0-9]{8} at src\/main\.ts:10$/)

    // Check the db file after add
    const { execFileSync: exec } = require('child_process')
    const lsOut = exec('ls', ['-la', require('os').homedir() + '/.local/share/agent-comments/'], { encoding: 'utf-8' })
    console.log('DEBUG db files:', lsOut)
    const catOut = exec('cat', [require('os').homedir() + '/.local/share/agent-comments/test-repo.json'], { encoding: 'utf-8' })
    console.log('DEBUG db content:', catOut)

    const listOut = fixture.tsx('get')
    console.log('DEBUG listOut:', JSON.stringify(listOut), typeof listOut)
    expect(listOut).toContain('fix the bug')
    expect(listOut).toContain('active')
  })

  // it('resolves a comment', () => {
  //   tsx('add', 'src/other.ts', '5', 'wip')
  //   const all = tsx('get', '-s', 'all')
  //   const resolvedLine = all.split('\n').find((l: string) => l.includes('wip'))
  //   expect(resolvedLine).toBeTruthy()
  //   const shortId = resolvedLine!.split('|')[0].slice(0, 8)
  //   const resOut = tsx('resolve', shortId)
  //   expect(resOut).toContain('Resolved')
  //
  //   const active = tsx('get')
  //   expect(active).not.toContain('wip')
  //   expect(active).toContain('fix the bug')
  //
  //   const all2 = tsx('get', '-s', 'all')
  //   expect(all2).toContain('wip')
  // })
  //
  // it('supports json view', () => {
  //   const out = tsx('get', '--view', 'json')
  //   const parsed = JSON.parse(out)
  //   expect(parsed.comments).toBeInstanceOf(Array)
  // })
  //
  // it('supports table view', () => {
  //   const out = tsx('get', '--view', 'table', '-s', 'all')
  //   expect(out).toMatch(/● [a-f0-9]{8}/)
  // })
  //
  // it('deletes a comment', () => {
  //   const all = tsx('get', '-s', 'all')
  //   const firstLine = all.split('\n')[0]
  //   const shortId = firstLine.split('|')[0].slice(0, 8)
  //   tsx('delete', shortId)
  //   const after = tsx('get', '-s', 'all')
  //   expect(after).not.toContain(shortId)
  // })
})
