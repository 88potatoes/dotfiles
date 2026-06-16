#!/usr/bin/env node --experimental-strip-types --no-warnings

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "fs";
import { join, resolve, relative } from "path";
import { execSync } from "child_process";
import { randomUUID } from "crypto";

// ── Types ──────────────────────────────────────────────────────────────

interface Comment {
  id: string;
  file: string; // relative to repo root
  startLine: number;
  endLine: number;
  message: string;
  status: "active" | "resolved";
  createdAt: string;
  updatedAt: string;
}

interface CommentsStore {
  comments: Comment[];
}

// ── Helpers ────────────────────────────────────────────────────────────

function getRepoRoot(): string {
  try {
    return execSync("git rev-parse --show-toplevel", { encoding: "utf-8" }).trim();
  } catch {
    return process.cwd();
  }
}

function storeDir(): string {
  return join(getRepoRoot(), ".idea");
}

function storePath(): string {
  return join(storeDir(), "agent-comments.json");
}

function load(): CommentsStore {
  const path = storePath();
  if (!existsSync(path)) return { comments: [] };
  return JSON.parse(readFileSync(path, "utf-8")) as CommentsStore;
}

function save(store: CommentsStore): void {
  const dir = storeDir();
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(storePath(), JSON.stringify(store, null, 2) + "\n");
}

function resolveFilePath(file: string): string {
  const root = getRepoRoot();
  const abs = resolve(file);
  return relative(root, abs);
}

function parseLines(lines: string): { start: number; end: number } {
  const parts = lines.split(/[-:]/);
  const start = parseInt(parts[0], 10);
  const end = parts.length > 1 ? parseInt(parts[1], 10) : start;
  if (isNaN(start) || isNaN(end)) {
    console.error("Invalid line range. Use N or N:M (e.g. 10 or 10:20)");
    process.exit(1);
  }
  return { start, end };
}

function findComment(store: CommentsStore, id: string): Comment {
  const comment = store.comments.find((c) => c.id === id || c.id.startsWith(id));
  if (!comment) {
    console.error(`Comment not found: ${id}`);
    process.exit(1);
  }
  return comment;
}

function printComments(comments: Comment[]): void {
  if (comments.length === 0) {
    console.log("No comments.");
    return;
  }
  for (const c of comments) {
    const lines = c.startLine === c.endLine ? `L${c.startLine}` : `L${c.startLine}-${c.endLine}`;
    const status = c.status === "resolved" ? "✓" : "●";
    console.log(`${status} ${c.id.slice(0, 8)}  ${c.file}:${lines}`);
    console.log(`  ${c.message}`);
  }
}

// ── Commands ───────────────────────────────────────────────────────────

function cmdAdd(args: string[]): void {
  // agent-comments add <file> -l <lines> -m <message>
  // agent-comments add <file> <lines> <message...>
  if (args.length < 3) {
    console.error("Usage: agent-comments add <file> <lines> <message>");
    console.error("       agent-comments add <file> -l <lines> -m <message>");
    process.exit(1);
  }

  let file: string | undefined;
  let lines: string | undefined;
  let message: string | undefined;

  // Parse flags or positional
  if (args.includes("-l") || args.includes("-m")) {
    file = args[0];
    for (let i = 1; i < args.length; i++) {
      if (args[i] === "-l" && args[i + 1]) {
        lines = args[++i];
      } else if (args[i] === "-m" && args[i + 1]) {
        message = args.slice(i + 1).join(" ");
        break;
      }
    }
  } else {
    file = args[0];
    lines = args[1];
    message = args.slice(2).join(" ");
  }

  if (!file || !lines || !message) {
    console.error("Usage: agent-comments add <file> <lines> <message>");
    process.exit(1);
  }

  const { start, end } = parseLines(lines);
  const relFile = resolveFilePath(file);

  const store = load();
  const comment: Comment = {
    id: randomUUID(),
    file: relFile,
    startLine: start,
    endLine: end,
    message,
    status: "active",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  store.comments.push(comment);
  save(store);
  console.log(`Added ${comment.id.slice(0, 8)} at ${relFile}:L${start}-${end}`);
}

function cmdDelete(args: string[]): void {
  if (args.length < 1) {
    console.error("Usage: agent-comments delete <comment_id>");
    process.exit(1);
  }
  const store = load();
  const comment = findComment(store, args[0]);
  store.comments = store.comments.filter((c) => c.id !== comment.id);
  save(store);
  console.log(`Deleted ${comment.id.slice(0, 8)}`);
}

function cmdResolve(args: string[]): void {
  if (args.length < 1) {
    console.error("Usage: agent-comments resolve <comment_id>");
    process.exit(1);
  }
  const store = load();
  const comment = findComment(store, args[0]);
  comment.status = "resolved";
  comment.updatedAt = new Date().toISOString();
  save(store);
  console.log(`Resolved ${comment.id.slice(0, 8)}`);
}

function cmdUnresolve(args: string[]): void {
  if (args.length < 1) {
    console.error("Usage: agent-comments unresolve <comment_id>");
    process.exit(1);
  }
  const store = load();
  const comment = findComment(store, args[0]);
  comment.status = "active";
  comment.updatedAt = new Date().toISOString();
  save(store);
  console.log(`Unresolved ${comment.id.slice(0, 8)}`);
}

function cmdGet(args: string[]): void {
  const store = load();
  const filter = args[0];

  let filtered: Comment[];
  if (filter === "resolved") {
    filtered = store.comments.filter((c) => c.status === "resolved");
  } else if (filter === "unresolved" || filter === "active") {
    filtered = store.comments.filter((c) => c.status === "active");
  } else if (filter) {
    // Maybe it's a file path
    const relFile = resolveFilePath(filter);
    filtered = store.comments.filter((c) => c.file === relFile);
  } else {
    filtered = store.comments;
  }

  if (process.stdout.isTTY) {
    printComments(filtered);
  } else {
    console.log(JSON.stringify(filtered, null, 2));
  }
}

// ── Main ───────────────────────────────────────────────────────────────

const [command, ...args] = process.argv.slice(2);

switch (command) {
  case "add":
    cmdAdd(args);
    break;
  case "delete":
  case "rm":
    cmdDelete(args);
    break;
  case "resolve":
    cmdResolve(args);
    break;
  case "unresolve":
    cmdUnresolve(args);
    break;
  case "get":
  case "list":
  case "ls":
    cmdGet(args);
    break;
  default:
    console.log(`agent-comments — per-repo inline comments for agents

Usage:
  agent-comments add <file> <lines> <message>
  agent-comments add <file> -l <lines> -m <message>
  agent-comments delete <comment_id>
  agent-comments resolve <comment_id>
  agent-comments unresolve <comment_id>
  agent-comments get [resolved|unresolved|<file>]

Lines: single (10) or range (10:20)
Comments stored in .idea/agent-comments.json
Short IDs (8-char prefix) accepted for comment_id.
Pipes JSON output; TTY gets human-readable output.`);
    if (command && command !== "help" && command !== "--help" && command !== "-h") {
      process.exit(1);
    }
    break;
}
