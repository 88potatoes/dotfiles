import { JSONFilePreset } from 'lowdb/node'
import { Comment } from '../comments/comments.table.ts'
import { Low } from 'lowdb';
import { execSync } from 'child_process';
import { join, basename } from 'path';
import { homedir } from 'os';
import { mkdirSync, existsSync } from 'fs';

interface Data {
  comments: Comment[];
}

function getRepoRoot(): string {
  try {
    return execSync('git rev-parse --show-toplevel', {
      encoding: 'utf-8',
      stdio: 'pipe',
    }).trim();
  } catch {
    return process.cwd();
  }
}

function getDbPath(): string {
  const repoRoot = getRepoRoot();
  // Use the repo directory name as the filename (unique enough in practice)
  const name = basename(repoRoot);
  const dir = join(homedir(), '.local', 'share', 'agent-comments');
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  return join(dir, `${name}.json`);
}

const defaultData: Data = { comments: [] }
const dbPath = getDbPath();
export const db: Low<Data> = await JSONFilePreset<Data>(dbPath, defaultData)
