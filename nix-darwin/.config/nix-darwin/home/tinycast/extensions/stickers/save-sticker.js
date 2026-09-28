const { Clipboard, Toast, getPreferenceValues, showHUD } = require("@raycast/api");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

const run = promisify(execFile);

// Tinycast's own clipboard history captures images from every app and stores them as files.
const HISTORY_DB = path.join(os.homedir(), "Library/Application Support/com.tinycast.app/clipboard.sqlite3");

const IMAGE_EXTS = new Set([".png", ".gif", ".jpg", ".jpeg", ".webp", ".apng", ".bmp", ".tiff", ".heic"]);

function stickersDir() {
  const prefs = getPreferenceValues();
  const raw = prefs.stickersFolder || "~/Pictures/Stickers";
  return raw.startsWith("~") ? path.join(os.homedir(), raw.slice(1)) : raw;
}

// Guess the image format from magic bytes so files always get the right extension.
function sniffExt(buf) {
  if (buf.length >= 4 && buf[0] === 0x89 && buf[1] === 0x50) return "png";
  if (buf.length >= 3 && buf.slice(0, 3).toString("ascii") === "GIF") return "gif";
  if (buf.length >= 2 && buf[0] === 0xff && buf[1] === 0xd8) return "jpg";
  if (buf.length >= 12 && buf.slice(0, 4).toString("ascii") === "RIFF" && buf.slice(8, 12).toString("ascii") === "WEBP") return "webp";
  return null;
}

function extFromMime(mime) {
  const map = { "image/png": "png", "image/gif": "gif", "image/jpeg": "jpg", "image/webp": "webp" };
  return map[mime] || null;
}

// Find a name that doesn't collide: "cat.gif" -> "cat (2).gif"
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

// Timestamped fallback name like "sticker-2025-09-28-15-39-12.png"
function defaultName(ext) {
  const stamp = new Date()
    .toISOString()
    .replace(/[:T]/g, "-")
    .slice(0, 19);
  return `sticker-${stamp}.${ext}`;
}

// Copy an image file on disk into the stickers folder. Returns the saved path.
function saveFile(filePath, forcedBaseName = null) {
  const buf = fs.readFileSync(filePath);
  const origExt = path.extname(filePath).toLowerCase();
  const ext = IMAGE_EXTS.has(origExt) ? origExt.slice(1) : sniffExt(buf);
  if (!ext) throw new Error("That file is not a recognized image format");
  const baseName = forcedBaseName || path.basename(filePath, origExt);
  const dest = uniquePath(stickersDir(), baseName + "." + ext);
  fs.copyFileSync(filePath, dest);
  return dest;
}

// Download an image URL and save it.
async function saveUrl(url) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Download failed (HTTP ${response.status})`);
  const buf = Buffer.from(await response.arrayBuffer());
  let ext = sniffExt(buf);
  if (!ext) ext = extFromMime(response.headers.get("content-type")?.split(";")[0] || "");
  if (!ext) throw new Error("That URL did not return a recognized image");
  let name;
  try {
    const pathname = new URL(url).pathname;
    const base = path.basename(pathname);
    if (base) name = path.basename(base, path.extname(base)) + "." + ext;
  } catch {}
  const dest = uniquePath(stickersDir(), name || defaultName(ext));
  fs.writeFileSync(dest, buf);
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

  const content = await Clipboard.read();
  let saved = null;
  try {
    if (content.file) {
      saved = saveFile(content.file);
    } else if (content.text && /^https?:\/\//i.test(content.text.trim())) {
      saved = await saveUrl(content.text.trim());
    } else {
      const historyImage = await newestHistoryImage();
      if (historyImage) saved = saveFile(historyImage, defaultName("png").replace(/\.png$/, ""));
    }
  } catch (error) {
    await Toast.show({ style: Toast.Style.Failure, title: "Could not save sticker", message: error.message });
    return;
  }

  if (!saved) {
    await Toast.show({
      style: Toast.Style.Failure,
      title: "No image on clipboard",
      message: "Copy an image first (or copy an image URL).",
    });
    return;
  }

  await showHUD(`Saved sticker "${path.basename(saved)}"`);
}

module.exports = saveSticker;
module.exports.default = saveSticker;
