const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const { mkdir, readdir, mkdtemp, stat, rm } = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");

const run = promisify(execFile);

const SIPS_FORMATS = {
  png: "png",
  jpeg: "jpeg",
  heic: "heic",
  avif: "avif",
  gif: "gif",
  bmp: "bmp",
};

const LABELS = {
  png: "PNG",
  jpeg: "JPEG",
  heic: "HEIC",
  avif: "AVIF",
  gif: "GIF",
  bmp: "BMP",
};

const FORMATS = Object.keys(SIPS_FORMATS);

// Converted files are referenced by the clipboard after copy, so keep them
// around in a stable directory and prune files older than 24h on each run.
const OUT_DIR = path.join(os.tmpdir(), "tinycast-image-converter");

const ONE_DAY_MS = 24 * 60 * 60 * 1000;

async function pruneOldOutputs() {
  try {
    const now = Date.now();
    const entries = await readdir(OUT_DIR);
    await Promise.all(
      entries.map(async (name) => {
        const full = path.join(OUT_DIR, name);
        const info = await stat(full).catch(() => null);
        if (info && now - info.mtimeMs > ONE_DAY_MS) {
          await rm(full, { recursive: true, force: true }).catch(() => {});
        }
      })
    );
  } catch {
    // first run, dir doesn't exist yet
  }
}

function sipsArgs(inputPath, outPath, format) {
  const args = ["-s", "format", SIPS_FORMATS[format]];
  if (format === "jpeg") args.push("-s", "formatOptions", "90");
  args.push(inputPath, "--out", outPath);
  return args;
}

/**
 * Convert images to a target format with sips.
 * Returns per-input results; failed conversions come back with an error.
 */
async function convertImages(inputPaths, format) {
  await mkdir(OUT_DIR, { recursive: true });
  await pruneOldOutputs();
  const tmpDir = await mkdtemp(path.join(OUT_DIR, "convert-"));

  return Promise.all(
    inputPaths.map(async (inputPath) => {
      const base = path.basename(inputPath, path.extname(inputPath));
      const outPath = path.join(tmpDir, `${base}.${format}`);
      try {
        await run("sips", sipsArgs(inputPath, outPath, format));
        return { inputPath, outPath };
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        const errorLine =
          message.split("\n").find((line) => /error/i.test(line)) ?? message.trim().split("\n").pop();
        return { inputPath, outPath, error: errorLine.replace(/^Error\s*\d*:\s*/i, "") };
      }
    })
  );
}

module.exports = { FORMATS, LABELS, convertImages };