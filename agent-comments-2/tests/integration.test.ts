import { describe, it } from "vitest";

import { execSync } from "child_process";

describe("agent-comments integration", () => {
  it("adds a comment and lists it", async () => {
    const stdout = execSync('npx tsx ./src/index.ts add "src/main.ts" 11 "fix the bug"', { encoding: 'utf-8' });
  });
});
