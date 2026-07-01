import { describe, it } from "vitest";

import { execSync } from "child_process";

describe("agent-comments integration", () => {
  it("adds a comment and lists it", async () => {
    console.log(execSync("which npx", { encoding: "utf8" }));
    console.log(execSync("pwd", { encoding: "utf8" }));
    console.log(process.env.VITEST);
    console.log(process.env.NODE_ENV);

    console.log('cwd', process.cwd())
    const stdout = execSync('npx tsx ./src/index.ts add "src/main.ts" 11 "fix the bug"', { encoding: 'utf-8' });
    console.log("===stdout", stdout)
  });
});
