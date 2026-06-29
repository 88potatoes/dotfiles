import { exec, execFileSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export function createRepoFixture() {
  const newTestDir = join(__dirname, "tmp");
  if (!existsSync(newTestDir)) {
    mkdirSync(newTestDir);
  }
  const repoDir = join(
    newTestDir,
    `test-repo-${Math.random().toString(24).slice(2)}`,
  );

  mkdirSync(repoDir, { recursive: true });
  execFileSync("git", ["init"], {
    cwd: repoDir,
    stdio: "pipe",
  });

  function tsx(...args: string[]) {
    const command = ['cd', repoDir, "&&", "../../../node_modules/.bin/tsx", ...args];
    const joinedCommand = command.join(' ');
    console.log("===joinedCommand", joinedCommand)
    exec(joinedCommand);
  }

  function cleanup() {
    rmSync(tmpDir, { recursive: true, force: true });
  }

  return {
    repoDir,
    tsx,
    cleanup,
  };
}
