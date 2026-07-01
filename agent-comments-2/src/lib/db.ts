import { execSync } from "node:child_process";
import { mkdirSync, existsSync } from "fs";
import { homedir } from "os";
import { join } from "path";
import Database from "better-sqlite3";

type DB = InstanceType<typeof Database>;

function getRepoRoot(): string {
  try {
    return execSync("git rev-parse --show-toplevel", {
      encoding: "utf-8",
      stdio: "pipe",
    }).trim();
  } catch {
    return process.cwd();
  }
}

export function getDbPath(): string {
  const repoRoot = getRepoRoot();
  const home = homedir();
  const relative = repoRoot.replace(home, "").replace(/^\//, "");
  const name = relative.replace(/\//g, "_");
  const dir = join(home, ".local", "share", "agent-comments");
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  return join(dir, `${name}.sqlite`);
}

const dbPath = getDbPath();
export const db: DB = new Database(dbPath);

// WAL mode for better concurrent reads
db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY,
    file TEXT NOT NULL,
    startLine INTEGER NOT NULL,
    endLine INTEGER NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'resolved')),
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  )
`);

console.log("DB PATH:", dbPath);
console.log("PID:", process.pid);
