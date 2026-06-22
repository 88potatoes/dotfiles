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
  const tmpDir = mkdtempSync('/tmp/ac-integration-')
  const repoDir = join(tmpDir, 'test-repo')

  mkdirSync(repoDir, { recursive: true })
  execFileSync('git', ['init'], {
    cwd: repoDir,
    stdio: 'pipe',
  })

  function tsx(...args: string[]) {
    const result = execFileSync(TSX, [CLI, ...args], {
      cwd: repoDir,
      encoding: 'utf-8' as const,
      timeout: 10000,
    })
    const trimmed = typeof result === 'string' ? result.trim() : result.toString().trim()
    return trimmed
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
