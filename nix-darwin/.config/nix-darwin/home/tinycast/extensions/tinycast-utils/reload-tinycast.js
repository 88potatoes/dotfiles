const { showHUD, closeMainWindow } = require("@raycast/api");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const { setTimeout: sleep } = require("node:timers/promises");

const run = promisify(execFile);

module.exports = async function reloadTinycast() {
  await closeMainWindow().catch(() => {});
  await showHUD("TinyCast: reloading…");

  await run("osascript", ["-e", 'tell application "Tinycast" to quit']).catch(() => {});
  await sleep(1500);
  await run("open", ["-a", "Tinycast"]);

  await showHUD("TinyCast: reloaded");
};