import { execFileSync } from "child_process";
import { mkdirSync, mkdtempSync, rmSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)
const projectRoot = join(__dirname, '..')

const TSX = join(projectRoot, 'node_modules', '.bin', 'tsx')
const CLI = join(projectRoot, 'src/index.ts')

export function createRepoFixture() {
  const tmpDir = mkdtempSync('/tmp/agent-comment-integration-tests')
  const repoDir = join(tmpDir, `test-repo-${Math.random().toString(24).slice(2)}`)

  mkdirSync(repoDir, { recursive: true })
  execFileSync('git', ['init'], {
    cwd: repoDir,
    stdio: 'pipe',
  })

  function tsx(...args: string[]) {
    const result: string = execFileSync(TSX, [CLI, ...args], {
      cwd: repoDir,
      encoding: 'utf-8' as const,
      timeout: 10000,
    }).trim();
    return result;
  }

  function cleanup() {
    rmSync(tmpDir, { recursive: true, force: true })
  }

  return {
    repoDir,
    tsx,
    cleanup,
  }
}
