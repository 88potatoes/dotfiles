const { Clipboard, Toast, getPreferenceValues, showHUD } = require("@raycast/api");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");

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
function saveFile(filePath) {
  const buf = fs.readFileSync(filePath);
  const origExt = path.extname(filePath).toLowerCase();
  const ext = IMAGE_EXTS.has(origExt) ? origExt.slice(1) : sniffExt(buf);
  if (!ext) throw new Error("That file is not a recognized image format");
  const dest = uniquePath(stickersDir(), path.basename(filePath, origExt) + "." + ext);
  fs.copyFileSync(filePath, dest);
  return dest;
}

// Save a clipboard image (a file path or a data URI).
function saveImageContent(image) {
  const source = image.source || "";
  if (source.startsWith("data:")) {
    const match = /^data:([^;]+);base64,(.*)$/s.exec(source);
    const ext = match ? extFromMime(match[1]) : null;
    const buf = Buffer.from(match ? match[2] : source.replace(/^data:[^,]*,/, ""), "base64");
    const detected = sniffExt(buf) || ext;
    if (!detected) throw new Error("Could not detect the image format");
    const dest = uniquePath(stickersDir(), defaultName(detected));
    fs.writeFileSync(dest, buf);
    return dest;
  }
  return saveFile(source);
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

async function saveSticker() {
  fs.mkdirSync(stickersDir(), { recursive: true });

  const content = await Clipboard.read();
  let saved = null;
  try {
    if (content.file) {
      saved = saveFile(content.file);
    } else if (content.image) {
      saved = saveImageContent(content.image);
    } else if (content.text && /^https?:\/\//i.test(content.text.trim())) {
      saved = await saveUrl(content.text.trim());
    }
  } catch (error) {
    await Toast.show({ style: Toast.Style.Failure, title: "Could not save sticker", message: error.message });
    return;
  }

  if (!saved) {
    await Toast.show({
      style: Toast.Style.Failure,
      title: "No image on clipboard",
      message: "Right-click an image and pick Copy Image first (or copy an image URL).",
    });
    return;
  }

  await showHUD(`Saved sticker "${path.basename(saved)}"`);
}

module.exports = saveSticker;
module.exports.default = saveSticker;
