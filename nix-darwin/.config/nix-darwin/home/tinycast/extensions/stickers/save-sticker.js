const { Clipboard, Toast, getPreferenceValues, showHUD } = require("@raycast/api");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const run = promisify(execFile);

// Tinycast's own clipboard history captures images from every app and stores them as files.
const HISTORY_DB = path.join(os.homedir(), "Library/Application Support/com.tinycast.app/clipboard.sqlite3");

const STICKER_SIZE = 256;

function stickersDir() {
  const prefs = getPreferenceValues();
  const raw = prefs.stickersFolder || "~/Pictures/Stickers";
  return raw.startsWith("~") ? path.join(os.homedir(), raw.slice(1)) : raw;
}

// Find a name that doesn't collide: "cat.jpg" -> "cat (2).jpg"
function uniquePath(dir, name) {
  const ext = path.extname(name);
  const base = path.basename(name, ext);
  let candidate = path.join(dir, name);
  let i = 2;
  while (fs.existsSync(candidate)) {
    candidate = path.join(dir, `${base} (${i})${ext}`);
    i++;
  }
  return candidate;
}

// Timestamped fallback name like "sticker-2025-09-28-15-39-12"
function defaultBaseName() {
  const stamp = new Date()
    .toISOString()
    .replace(/[:T]/g, "-")
    .slice(0, 19);
  return `sticker-${stamp}`;
}

// Square center-crop, downscale to 256x256. Images with transparency save as PNG
// (JPEG has no alpha channel); fully opaque ones save as smaller JPEGs. Falls back
// to a plain copy if sips can't process the file, so a weird image is never lost.
async function processSticker(srcPath, baseName) {
  let dims = null;
  let hasAlpha = false;
  try {
    const { stdout } = await run("/usr/bin/sips", ["-g", "pixelWidth", "-g", "pixelHeight", "-g", "hasAlpha", srcPath]);
    const nums = stdout
      .split("\n")
      .map((line) => parseInt(line.split(":")[1] || "", 10))
      .filter((n) => !isNaN(n));
    if (nums.length >= 2) dims = nums.slice(0, 2);
    hasAlpha = /hasAlpha:\s*yes/i.test(stdout);
  } catch {}

  const format = hasAlpha ? "png" : "jpeg";
  const dest = uniquePath(stickersDir(), `${baseName}.${format === "png" ? "png" : "jpg"}`);
  try {
    let crop = [];
    if (dims) {
      const square = Math.min(...dims);
      crop = ["-c", String(square), String(square)];
    }
    await run("/usr/bin/sips", [
      ...crop,
      "-Z", String(STICKER_SIZE),
      "-s", "format", format,
      "-s", "formatOptions", "85",
      "--out", dest,
      srcPath,
    ]);
  } catch {
    fs.copyFileSync(srcPath, dest);
  }
  return dest;
}

// Newest image in Tinycast's clipboard history — covers "Copy Image" in browsers,
// which never reaches Clipboard.read() because Tinycast's clipboard API is text-only.
async function newestHistoryImage() {
  try {
    const { stdout } = await run("/usr/bin/sqlite3", [
      "-readonly", HISTORY_DB,
      "SELECT image_path FROM items WHERE kind='image' AND image_path IS NOT NULL ORDER BY created_at DESC LIMIT 1",
    ]);
    const imagePath = stdout.trim();
    if (imagePath && fs.existsSync(imagePath)) return imagePath;
  } catch {}
  return null;
}

async function saveSticker() {
  fs.mkdirSync(stickersDir(), { recursive: true });

  let srcPath = null;
  let baseName = defaultBaseName();
  let tempPath = null;

  try {
    const content = await Clipboard.read();
    if (content.file) {
      srcPath = content.file;
      baseName = path.basename(srcPath, path.extname(srcPath)) || baseName;
    } else if (content.text && /^https?:\/\//i.test(content.text.trim())) {
      const response = await fetch(content.text.trim());
      if (!response.ok) throw new Error(`Download failed (HTTP ${response.status})`);
      tempPath = path.join(os.tmpdir(), `tinycast-sticker-${Date.now()}`);
      fs.writeFileSync(tempPath, Buffer.from(await response.arrayBuffer()));
      srcPath = tempPath;
      try {
        const base = path.basename(new URL(content.text.trim()).pathname);
        const name = path.basename(base, path.extname(base));
        if (name) baseName = name;
      } catch {}
    } else {
      srcPath = await newestHistoryImage();
    }

    if (!srcPath || !fs.existsSync(srcPath)) {
      await Toast.show({
        style: Toast.Style.Failure,
        title: "No image on clipboard",
        message: "Copy an image first (or copy an image URL).",
      });
      return;
    }

    const saved = await processSticker(srcPath, baseName);
    await showHUD(`Saved sticker "${path.basename(saved)}"`);
  } catch (error) {
    await Toast.show({ style: Toast.Style.Failure, title: "Could not save sticker", message: error.message });
  } finally {
    if (tempPath) fs.rmSync(tempPath, { force: true });
  }
}

module.exports = saveSticker;
module.exports.default = saveSticker;
