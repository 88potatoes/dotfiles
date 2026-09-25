const { Clipboard, showHUD } = require("@raycast/api");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const { mkdtemp, rm } = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");

const run = promisify(execFile);

// sips format names for the formats we expose
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

module.exports = function makeConvert(format) {
  const sipsFormat = SIPS_FORMATS[format];
  const label = LABELS[format];

  return async function convert() {
    const { file } = await Clipboard.read();

    if (!file) {
      await showHUD("Image Converter: no image on clipboard");
      return;
    }

    const tmpDir = await mkdtemp(path.join(os.tmpdir(), "tinycast-convert-"));
    const outPath = path.join(tmpDir, `converted.${format}`);

    try {
      const args = ["-s", "format", sipsFormat];
      if (format === "jpeg") args.push("-s", "formatOptions", "90");
      args.push(file, "--out", outPath);

      await run("sips", args);
      await Clipboard.copy({ file: outPath });
      await showHUD(`Image Converter: converted to ${label} → copied to clipboard`);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      await showHUD(`Image Converter: failed to convert (${message.trim().split("\n").pop()})`);
    } finally {
      await rm(tmpDir, { recursive: true, force: true }).catch(() => {});
    }
  };
};