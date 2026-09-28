const React = require("react");
const { Action, ActionPanel, Clipboard, closeMainWindow, confirmAlert, Grid, Icon, Toast } = require("@raycast/api");
const fs = require("node:fs");
const path = require("node:path");
const os = require("node:os");
const { getPreferenceValues } = require("@raycast/api");

const IMAGE_EXTS = new Set([".png", ".gif", ".jpg", ".jpeg", ".webp", ".apng", ".bmp", ".tiff", ".heic"]);

function stickersDir() {
  const prefs = getPreferenceValues();
  const raw = prefs.stickersFolder || "~/Pictures/Stickers";
  return raw.startsWith("~") ? path.join(os.homedir(), raw.slice(1)) : raw;
}

function listStickers() {
  const dir = stickersDir();
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((name) => IMAGE_EXTS.has(path.extname(name).toLowerCase()))
    .map((name) => {
      const filePath = path.join(dir, name);
      const stat = fs.statSync(filePath);
      return { name: path.basename(name, path.extname(name)), ext: path.extname(name).slice(1), filePath, mtime: stat.mtimeMs };
    })
    .sort((a, b) => b.mtime - a.mtime);
}

const h = React.createElement;

async function copySticker(sticker) {
  await Clipboard.copy({ file: sticker.filePath });
  await Toast.show({ style: Toast.Style.Success, title: `Copied "${sticker.name}"` });
}

async function pasteSticker(sticker) {
  await Clipboard.paste({ file: sticker.filePath });
  await closeMainWindow();
}

// Node has no built-in trash, so rename into ~/.Trash ourselves.
function trashFile(filePath) {
  const trashDir = path.join(os.homedir(), ".Trash");
  const base = path.basename(filePath);
  const ext = path.extname(base);
  let candidate = path.join(trashDir, base);
  let i = 2;
  while (fs.existsSync(candidate)) {
    candidate = path.join(trashDir, `${path.basename(base, ext)} (${i})${ext}`);
    i++;
  }
  fs.renameSync(filePath, candidate);
}

async function deleteSticker(sticker, reload) {
  await confirmAlert({
    title: `Delete "${sticker.name}.${sticker.ext}"?`,
    message: "This moves the file to the Trash.",
    icon: Icon.Trash,
  });
  trashFile(sticker.filePath);
  reload();
  await Toast.show({ style: Toast.Style.Success, title: `Deleted "${sticker.name}.${sticker.ext}"` });
}

function actionsFor(sticker, reload, extra) {
  return h(
    ActionPanel,
    null,
    extra,
    h(Action, { icon: Icon.CopyClipboard, title: "Copy Sticker", shortcut: { modifiers: ["cmd", "opt"], key: "c" }, onAction: () => copySticker(sticker) }),
    h(Action, { icon: Icon.Clipboard, title: "Paste Sticker", shortcut: { modifiers: ["cmd", "opt"], key: "p" }, onAction: () => pasteSticker(sticker) }),
    h(Action.ShowInFinder, { path: sticker.filePath }),
    h(Action, {
      icon: Icon.Trash,
      title: "Delete Sticker",
      shortcut: { modifiers: ["ctrl"], key: "x" },
      onAction: () => deleteSticker(sticker, reload),
    })
  );
}

function Stickers() {
  const [tick, setTick] = React.useState(0);
  const reload = React.useCallback(() => setTick((t) => t + 1), []);
  const stickers = React.useMemo(() => {
    void tick;
    return listStickers();
  }, [tick]);

  return h(
    Grid,
    {
      columns: 5,
      aspectRatio: "1",
      searchBarPlaceholder: "Search stickers…",
      throttle: true,
      actions: h(
        ActionPanel,
        null,
        h(Action.ShowInFinder, { path: stickersDir(), title: "Open Stickers Folder" }),
        h(Action, {
          icon: Icon.Plus,
          title: "Save Sticker from Clipboard",
          onAction: async () => {
            const saveSticker = require("./save-sticker");
            await saveSticker();
            reload();
          },
        })
      ),
    },
    h(Grid.EmptyView, { title: 'No stickers yet. Copy an image anywhere and run "Save Sticker from Clipboard".' }),
    stickers.map((sticker) =>
      h(
        Grid.Item,
        {
          key: sticker.filePath,
          title: sticker.name,
          subtitle: sticker.ext,
          content: { source: sticker.filePath, tooltip: `${sticker.name}.${sticker.ext}` },
          actions: actionsFor(sticker, reload),
        }
      )
    )
  );
}

module.exports = Stickers;
module.exports.default = Stickers;
