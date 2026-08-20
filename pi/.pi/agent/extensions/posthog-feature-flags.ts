import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { StringEnum } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	truncateHead,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import type { Static } from "typebox";

const DEFAULT_HOST = "https://app.posthog.com";
const REQUEST_TIMEOUT_MS = 15_000;
const MAX_PAGE_SIZE = 100;
const MAX_RESULTS = 500;
const MAX_PAGES = Math.ceil(MAX_RESULTS / MAX_PAGE_SIZE);

const Parameters = Type.Object({
	action: Type.Optional(
		StringEnum(["list", "get"] as const, {
			description: "List feature flags, or retrieve one flag by ID or key",
		}),
	),
	projectId: Type.Optional(
		Type.String({ description: "PostHog project ID. Defaults to POSTHOG_PROJECT_ID." }),
	),
	flagId: Type.Optional(Type.String({ description: "PostHog feature flag ID for the get action" })),
	key: Type.Optional(
		Type.String({ description: "Feature flag key; exact-match locally when listing or getting by key" }),
	),
	limit: Type.Optional(
		Type.Integer({ minimum: 1, maximum: MAX_RESULTS, description: "Maximum flags to read. Default: 100." }),
	),
	includeInactive: Type.Optional(
		Type.Boolean({ description: "Include inactive flags. Default: true." }),
	),
});

export type PostHogFeatureFlagsInput = Static<typeof Parameters>;

type FeatureFlag = Record<string, unknown>;

type FeatureFlagListResponse = {
	results?: unknown;
	next?: unknown;
};

type AuthFileEntry = {
	type?: string;
	key?: string;
	env?: Record<string, string>;
};

async function readPostHogAuth(): Promise<AuthFileEntry> {
	try {
		const contents = await readFile(join(homedir(), ".pi", "agent", "auth.json"), "utf8");
		const auth = JSON.parse(contents) as Record<string, AuthFileEntry>;
		return auth.posthog ?? {};
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return {};
		throw new Error(`Could not read PostHog credentials from auth.json: ${String(error)}`);
	}
}

function resolveAuthValue(value: string | undefined, env: Record<string, string>): string | undefined {
	if (!value) return undefined;
	if (!value.startsWith("$")) return value.trim();
	const name = value.slice(1);
	return (process.env[name] ?? env[name])?.trim();
}

async function getRequiredConfig(
	params: PostHogFeatureFlagsInput,
): Promise<{ apiKey: string; projectId: string; host: URL }> {
	const auth = await readPostHogAuth();
	const authEnv = auth.env ?? {};
	const apiKey =
		process.env.POSTHOG_PERSONAL_API_KEY?.trim() || resolveAuthValue(auth.key, authEnv);
	if (!apiKey) {
		throw new Error(
			"PostHog credentials are missing. Set POSTHOG_PERSONAL_API_KEY or add a posthog entry to ~/.pi/agent/auth.json.",
		);
	}

	const projectId =
		params.projectId?.trim() || process.env.POSTHOG_PROJECT_ID?.trim() || authEnv.POSTHOG_PROJECT_ID?.trim() || "";
	if (!projectId) {
		throw new Error("PostHog project ID is required. Pass projectId, set POSTHOG_PROJECT_ID, or add it to auth.json.");
	}

	const rawHost =
		(process.env.POSTHOG_HOST?.trim() || authEnv.POSTHOG_HOST?.trim() || DEFAULT_HOST).replace(/\/+$/, "");
	let host: URL;
	try {
		host = new URL(rawHost);
	} catch {
		throw new Error(`POSTHOG_HOST is not a valid URL: ${rawHost}`);
	}
	if (host.protocol !== "https:" && host.hostname !== "localhost" && host.hostname !== "127.0.0.1") {
		throw new Error("POSTHOG_HOST must use HTTPS unless it points to localhost.");
	}

	return { apiKey, projectId, host };
}

function createTimeoutSignal(signal: AbortSignal | undefined): AbortSignal {
	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

	const abort = () => controller.abort(signal?.reason);
	if (signal?.aborted) {
		abort();
	} else {
		signal?.addEventListener("abort", abort, { once: true });
	}

	controller.signal.addEventListener("abort", () => clearTimeout(timeout), { once: true });
	return controller.signal;
}

async function getJson(url: URL, apiKey: string, signal: AbortSignal | undefined): Promise<unknown> {
	const response = await fetch(url, {
		headers: {
			Accept: "application/json",
			Authorization: `Bearer ${apiKey}`,
		},
		signal: createTimeoutSignal(signal),
	});

	if (!response.ok) {
		const body = (await response.text()).replace(/\s+/g, " ").trim().slice(0, 300);
		const suffix = body ? `: ${body}` : "";
		throw new Error(`PostHog API returned HTTP ${response.status}${suffix}`);
	}

	return response.json();
}

function pageResults(payload: unknown): FeatureFlag[] {
	if (Array.isArray(payload)) return payload.filter(isFeatureFlag);
	if (!payload || typeof payload !== "object") return [];

	const results = (payload as FeatureFlagListResponse).results;
	return Array.isArray(results) ? results.filter(isFeatureFlag) : [];
}

function isFeatureFlag(value: unknown): value is FeatureFlag {
	return Boolean(value && typeof value === "object" && !Array.isArray(value));
}

function nextPage(payload: unknown): string | undefined {
	if (!payload || typeof payload !== "object") return undefined;
	const next = (payload as FeatureFlagListResponse).next;
	return typeof next === "string" && next.length > 0 ? next : undefined;
}

function isActive(flag: FeatureFlag): boolean {
	if (typeof flag.active === "boolean") return flag.active;
	if (typeof flag.is_active === "boolean") return flag.is_active;
	return true;
}

async function listFeatureFlags({
	host,
	projectId,
	apiKey,
	limit,
	includeInactive,
	signal,
}: {
	host: URL;
	projectId: string;
	apiKey: string;
	limit: number;
	includeInactive: boolean;
	signal: AbortSignal | undefined;
}): Promise<FeatureFlag[]> {
	const firstUrl = new URL(`/api/projects/${encodeURIComponent(projectId)}/feature_flags/`, host);
	firstUrl.searchParams.set("limit", String(Math.min(limit, MAX_PAGE_SIZE)));

	const flags: FeatureFlag[] = [];
	let url: URL | undefined = firstUrl;
	let pagesRead = 0;

	while (url && flags.length < limit && pagesRead < MAX_PAGES) {
		pagesRead += 1;
		const payload = await getJson(url, apiKey, signal);
		flags.push(...pageResults(payload));

		const next = nextPage(payload);
		if (!next || flags.length >= limit) break;

		const nextUrl = new URL(next, host);
		if (nextUrl.origin !== host.origin) break;
		url = nextUrl;
	}

	const filtered = includeInactive ? flags : flags.filter(isActive);
	return filtered.slice(0, limit);
}

async function getFeatureFlag({
	host,
	projectId,
	apiKey,
	flagId,
	signal,
}: {
	host: URL;
	projectId: string;
	apiKey: string;
	flagId: string;
	signal: AbortSignal | undefined;
}): Promise<FeatureFlag> {
	const url = new URL(
		`/api/projects/${encodeURIComponent(projectId)}/feature_flags/${encodeURIComponent(flagId)}/`,
		host,
	);
	const payload = await getJson(url, apiKey, signal);
	if (!isFeatureFlag(payload)) throw new Error("PostHog returned an unexpected feature flag response.");
	return payload;
}

function formatOutput(value: unknown): string {
	const output = truncateHead(JSON.stringify(value, null, 2), {
		maxBytes: DEFAULT_MAX_BYTES,
		maxLines: DEFAULT_MAX_LINES,
	});
	if (!output.truncated) return output.content;

	return `${output.content}\n\n[Output truncated: ${output.outputLines} of ${output.totalLines} lines (${formatSize(
		output.outputBytes,
	)} of ${formatSize(output.totalBytes)}).]`;
}

export default function postHogFeatureFlags(pi: ExtensionAPI) {
	pi.registerTool({
		name: "posthog_feature_flags",
		label: "PostHog Feature Flags",
		description:
			"Read PostHog feature flag metadata using a read-only personal API key. Supports listing flags, exact key filtering, and retrieving a flag by ID. Never writes or changes flags.",
		promptSnippet: "Read PostHog feature flag metadata",
		parameters: Parameters,
		async execute(_toolCallId, params, signal) {
			const { apiKey, projectId, host } = await getRequiredConfig(params);
			const action = params.action ?? "list";
			const includeInactive = params.includeInactive ?? true;
			const key = params.key?.trim();
			const flagId = params.flagId?.trim();
			const requestedLimit = Math.min(params.limit ?? (key ? MAX_RESULTS : 100), MAX_RESULTS);

			if (action === "get" && !flagId && !key) {
				throw new Error("The get action requires flagId or key.");
			}

			if (action === "get" && flagId) {
				const flag = await getFeatureFlag({ host, projectId, apiKey, flagId, signal });
				return {
					content: [{ type: "text", text: formatOutput(flag) }],
					details: { projectId, flag },
				};
			}

			const flags = await listFeatureFlags({
				host,
				projectId,
				apiKey,
				limit: requestedLimit,
				includeInactive,
				signal,
			});
			const matchingFlags = key ? flags.filter((flag) => flag.key === key) : flags;

			if (action === "get") {
				if (!key) throw new Error("The get action requires flagId or key.");
				const flag = matchingFlags[0];
				if (!flag) {
					return {
						content: [{ type: "text", text: `No PostHog feature flag found with key: ${key}` }],
						details: { projectId, flag: null },
					};
				}
				return {
					content: [{ type: "text", text: formatOutput(flag) }],
					details: { projectId, flag },
				};
			}

			const result = {
				projectId,
				count: matchingFlags.length,
				flags: matchingFlags,
			};
			return {
				content: [{ type: "text", text: formatOutput(result) }],
				details: result,
			};
		},
	});
}
