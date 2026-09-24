#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const os = require("os");

let token = process.env.FIGMA_TOKEN || process.env.FIGMA_API_KEY;

if (!token) {
  const authPath = path.join(os.homedir(), ".pi", "agent", "auth.json");
  try {
    if (fs.existsSync(authPath)) {
      const auth = JSON.parse(fs.readFileSync(authPath, "utf8"));
      const figma = auth.figma || auth.FIGMA_TOKEN || auth.FIGMA_API_KEY;
      if (typeof figma === "string") {
        token = figma;
      } else if (figma && typeof figma === "object") {
        token = figma.key || figma.token || figma.apiKey;
      }
    }
  } catch (err) {
    console.error("Error reading " + authPath + ":", err.message);
  }
}

if (!token || !token.trim()) {
  console.error(
    "FIGMA_TOKEN not found. Set it in ~/.pi/agent/auth.json (under 'figma'), " +
    "via environment variable FIGMA_TOKEN, or run /figma-auth."
  );
  process.exit(1);
}

process.stdout.write(token.trim());
