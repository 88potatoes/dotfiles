import { describe, it, beforeEach, afterEach } from "vitest";

import { createRepoFixture } from "./helpers.ts";

describe("agent-comments integration", () => {
  let fixture: ReturnType<typeof createRepoFixture>;

  beforeEach(() => {
    fixture = createRepoFixture();
  });

  afterEach(() => {
    // fixture.cleanup();
  });

  it("adds a comment and lists it", async () => {
    const addOut = fixture.tsx("add", "src/main.ts", "11", "fix the bug");
    console.log("===addOut", addOut)
    console.log('============================')
    // console.log("===addOut", addOut)
    // expect(addOut).toMatch(/^Added [a-f0-9]{8} at src\/main\.ts:10$/);
    //
    // await new Promise((resolve) => setTimeout(resolve, 60_000));
    //
    const addDb = fixture.tsx("debug", "pwd");
    // console.log("ADD DB:", addDb);
    //
    // // Read the db file directly
    // const { readFileSync, existsSync } = await import("fs");
    // const exists = existsSync(addDb);
    // console.log("DB exists:", exists);
    // if (exists) {
    //   const content = readFileSync(addDb, "utf-8");
    //   console.log("DB content:", content);
    // }
    //
    // const listOut = fixture.tsx("get");
    // console.log("GET:", JSON.stringify(listOut));
    // console.log("GET type:", typeof listOut, "length:", listOut.length);
    //
    // expect(listOut).toContain("fix the bug");
    // expect(listOut).toContain("active");
  });

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
});
