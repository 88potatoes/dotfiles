const { useState, useEffect, useCallback } = require("react");
const { jsx, jsxs, Fragment } = require("react/jsx-runtime");
const {
  List,
  ActionPanel,
  Action,
  Icon,
  Clipboard,
  environment,
  showHUD,
} = require("@raycast/api");
const { stat, mkdir, readdir, mkdtemp, rm } = require("node:fs/promises");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
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
        const args = ["-s", "format", SIPS_FORMATS[format]];
        if (format === "jpeg") args.push("-s", "formatOptions", "90");
        args.push(inputPath, "--out", outPath);
        await run("sips", args);
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

const IMAGE_EXTENSIONS = [
  ".png", ".jpg", ".jpeg", ".heic", ".heif", ".avif", ".gif",
  ".bmp", ".tiff", ".tif", ".webp", ".jp2", ".psd", ".exr", ".pdf",
];

function isImagePath(p) {
  const ext = p.slice(p.lastIndexOf(".")).toLowerCase();
  return IMAGE_EXTENSIONS.includes(ext);
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function ConvertImage() {
  const [paths, setPaths] = useState([]);
  const [sizes, setSizes] = useState({});
  const [isConverting, setIsConverting] = useState(false);

  // Seed from clipboard so "copy image, run command" still works
  useEffect(() => {
    Clipboard.read().then(({ file }) => {
      if (file && isImagePath(file)) {
        setPaths((prev) => (prev.length ? prev : [file]));
      }
    });
  }, []);

  useEffect(() => {
    paths.forEach((p) => {
      if (sizes[p] !== undefined) return;
      stat(p)
        .then((info) => setSizes((prev) => ({ ...prev, [p]: info.size })))
        .catch(() => setSizes((prev) => ({ ...prev, [p]: null })));
    });
  }, [paths]);

  const onDrop = useCallback((event) => {
    if (event.type === "file") {
      setPaths(event.files);
    }
  }, []);

  const convert = useCallback(
    async (format) => {
      if (!paths.length) return;
      setIsConverting(true);
      try {
        const results = await convertImages(paths, format);
        const ok = results.filter((r) => !r.error);
        const failed = results.filter((r) => r.error);

        if (ok.length) {
          await Clipboard.copy({ file: ok[ok.length - 1].outPath });
        }

        if (ok.length && !failed.length) {
          await showHUD(
            `Converted ${ok.length === 1 ? "image" : `${ok.length} images`} to ${LABELS[format]} → copied to clipboard`
          );
        } else if (ok.length) {
          await showHUD(`Converted ${ok.length} to ${LABELS[format]}, ${failed.length} failed`);
        } else {
          await showHUD(`Conversion failed: ${failed[0].error}`);
        }
      } finally {
        setIsConverting(false);
      }
    },
    [paths]
  );

  return jsx(List, {
    isLoading: isConverting,
    onDrop: onDrop,
    searchBarPlaceholder: "Drop an image above — choose a format below",
    children: [
      jsx(List.EmptyView, {
        key: "empty",
        icon: Icon.Image,
        title: "Drop an image here",
        subtitle: "Or copy one to the clipboard, then run this command",
      }),
      ...paths.map((p) =>
        jsx(
          List.Item,
          {
            key: p,
            title: path.basename(p),
            subtitle: sizes[p] ? formatBytes(sizes[p]) : undefined,
            icon: { source: p },
            accessories: [{ text: p.replace(environment.homePath, "~") }],
            actions: jsxs(ActionPanel, {
              children: [
                jsx(
                  ActionPanel.Section,
                  { title: "Convert To" },
                  FORMATS.map((format) =>
                    jsx(Action, {
                      key: format,
                      title: `Convert to ${LABELS[format]}`,
                      icon: Icon.ArrowRight,
                      onAction: () => convert(format),
                    })
                  )
                ),
                jsxs(
                  ActionPanel.Section,
                  {},
                  jsx(Action.CopyToClipboard, { title: "Copy Original", content: p }),
                  jsx(Action.ShowInFinder, null)
                ),
              ],
            }),
          },
          p
        )
      ),
    ],
  });
}

module.exports = ConvertImage;