import { execSync } from "node:child_process";
import { mkdirSync, existsSync } from "fs";
import { homedir } from "os";
import { join } from "path";

import { Low } from "lowdb";
import { JSONFilePreset, JSONFileSyncPreset } from "lowdb/node";

import { CommentRecord } from "../comments/comments.table.ts";

interface Data {
  comments: CommentRecord[];
}

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
  // Use the full path relative to ~, with / replaced by _ for uniqueness
  const home = homedir();
  const relative = repoRoot.replace(home, "").replace(/^\//, "");
  const name = relative.replace(/\//g, "_");
  const dir = join(home, ".local", "share", "agent-comments");
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
  return join(dir, `${name}.json`);
}

const defaultData: Data = { comments: [] };
const dbPath = getDbPath();
export const db = JSONFileSyncPreset<Data>(dbPath, defaultData);
