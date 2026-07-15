import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

// Ensure every bash tool call has a timeout, so nothing hangs forever.
// Default floor (5 min); the agent can set longer for known-slow ops.

// Tuning:
//   - When the agent/model supplies no `timeout` on a bash call, set the default.
//   - When a tiny `timeout` (<= 1s) is supplied, bump to the default (interpreted as "asap").
//   - Hard cap at 30 min so a runaway value can't park a turn indefinitely.

const DEFAULT_TIMEOUT_SEC = 300; // 5 min
const MIN_TIMEOUT_SEC = 5;
const MAX_TIMEOUT_SEC = 1800; // 30 min

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", (event) => {
		if (event.toolName !== "bash") return undefined;

		const t = event.input.timeout;
		if (typeof t !== "number" || t < MIN_TIMEOUT_SEC) {
			event.input.timeout = DEFAULT_TIMEOUT_SEC;
		} else if (t > MAX_TIMEOUT_SEC) {
			event.input.timeout = MAX_TIMEOUT_SEC;
		}
		return undefined;
	});
}
