/**
 * `/subscription-limits` -- one line per usage window of every subscription the
 * harness holds credentials for: Anthropic (Claude) and OpenAI (Codex).
 *
 * The two providers are polled independently and a provider that cannot answer
 * degrades to a single explanatory line instead of failing the command. These
 * are the undocumented endpoints the official clients call, so a missing login,
 * an expired token, a rejected credential, or a changed payload has to read as
 * a diagnosis rather than a stack trace.
 *
 * @module dsh-command-subscription-limits
 */

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const name = "command-subscription-limits";
const inject = ["commands"];

const REQUEST_TIMEOUT_MS = 10000;
const BAR_CELLS = 10;

const ANTHROPIC_OAUTH_HEADERS = { "anthropic-beta": "oauth-2025-04-20" };
const ANTHROPIC_USAGE_URL = "https://api.anthropic.com/api/oauth/usage";
const ANTHROPIC_PROFILE_URL = "https://api.anthropic.com/api/oauth/profile";
const CODEX_USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";

/** A provider outcome whose message is already meant for the user to read. */
class ProviderError extends Error {}

/**
 * One subscription the command reports on.
 * @typedef {object} Provider
 * @property {string} id - key under `providers` in the harness credential store.
 * @property {string} label - name shown in the report.
 * @property {string} signInHint - what to do when the credential is unusable.
 * @property {(token: string) => Promise<Usage>} read - fetches the usage report.
 */

/**
 * @typedef {object} Usage
 * @property {string} [plan] - subscription tier, when the provider discloses one.
 * @property {Window[]} windows - the provider's usage windows, longest last.
 */

/**
 * @typedef {object} Window
 * @property {string} label - window length, e.g. `5h`.
 * @property {number} percent - consumed share of the window, 0-100.
 * @property {Date} [resetsAt] - when the window rolls over, when disclosed.
 */

/** @type {Provider[]} */
const PROVIDERS = [
  {
    id: "anthropic",
    label: "Claude",
    signInHint: "sign in from `dsh web` -> Settings",
    read: readAnthropicUsage,
  },
  {
    id: "openai-codex",
    label: "Codex",
    signInHint: "sign in from `dsh web` -> Settings -> Codex",
    read: readCodexUsage,
  },
];

/** Path of the OAuth store the subscription plugins write. */
function credentialStorePath() {
  const dshHome = process.env.DSH_HOME ?? join(homedir(), ".dsh");
  return join(dshHome, "dsh-auth", "credentials.json");
}

/**
 * The provider's stored access token.
 * @param {Provider} provider - subscription whose credential is wanted.
 * @returns {string} a token that had not expired when it was read.
 * @throws {ProviderError} when the store, the record, or the token is unusable.
 */
function readAccessToken(provider) {
  const path = credentialStorePath();
  let store;
  try {
    store = JSON.parse(readFileSync(path, "utf8"));
  } catch (cause) {
    throw new ProviderError(
      cause?.code === "ENOENT"
        ? `no credential store at ${path}`
        : `credential store unreadable (${describe(cause)})`,
    );
  }

  const record = store?.providers?.[provider.id];
  if (!record?.access) {
    throw new ProviderError(`not signed in; ${provider.signInHint}`);
  }
  if (typeof record.expires === "number" && record.expires <= Date.now()) {
    throw new ProviderError(
      `credentials expired ${formatMoment(new Date(record.expires))}; ${provider.signInHint}`,
    );
  }
  return record.access;
}

/**
 * GET a JSON document with a bearer token.
 * @param {string} url - endpoint to read.
 * @param {string} token - bearer credential.
 * @param {Record<string, string>} [extraHeaders] - provider-specific headers.
 * @returns {Promise<unknown>} the parsed body.
 * @throws {ProviderError} on transport, status, or parse failure.
 */
async function fetchJson(url, token, extraHeaders) {
  const host = new URL(url).host;
  let response;
  try {
    response = await fetch(url, {
      headers: {
        authorization: `Bearer ${token}`,
        accept: "application/json",
        ...extraHeaders,
      },
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
  } catch (cause) {
    throw new ProviderError(`${host} unreachable (${describe(cause)})`);
  }

  if (response.status === 401 || response.status === 403) {
    throw new ProviderError(`credentials rejected by ${host} (HTTP ${response.status})`);
  }
  if (!response.ok) {
    throw new ProviderError(`${host} answered HTTP ${response.status}`);
  }

  try {
    return await response.json();
  } catch {
    throw new ProviderError(`${host} returned a body that is not JSON`);
  }
}

/**
 * Anthropic's rolling session and weekly windows.
 * @param {string} token - Anthropic OAuth access token.
 * @returns {Promise<Usage>} the five-hour and seven-day windows.
 * @throws {ProviderError} when no window can be read.
 */
async function readAnthropicUsage(token) {
  const usage = await fetchJson(ANTHROPIC_USAGE_URL, token, ANTHROPIC_OAUTH_HEADERS);
  const windows = [
    toWindow("5h", usage?.five_hour?.utilization, parseMoment(usage?.five_hour?.resets_at)),
    toWindow("7d", usage?.seven_day?.utilization, parseMoment(usage?.seven_day?.resets_at)),
  ].filter(Boolean);

  if (windows.length === 0) {
    throw new ProviderError("the usage response carried no windows");
  }
  return { plan: await readAnthropicPlan(token), windows };
}

/**
 * The subscription tier, which decorates the report and is never required:
 * a profile lookup that fails leaves the provider line unlabelled.
 * @param {string} token - Anthropic OAuth access token.
 * @returns {Promise<string | undefined>} `Max`, `Pro`, or nothing.
 */
async function readAnthropicPlan(token) {
  try {
    const account = (await fetchJson(ANTHROPIC_PROFILE_URL, token, ANTHROPIC_OAUTH_HEADERS))
      ?.account;
    if (account?.has_claude_max) return "Max";
    if (account?.has_claude_pro) return "Pro";
    return undefined;
  } catch {
    return undefined;
  }
}

/**
 * Codex's primary (5h) and secondary (weekly) rate-limit windows.
 * @param {string} token - ChatGPT OAuth access token.
 * @returns {Promise<Usage>} both rate-limit windows.
 * @throws {ProviderError} when no window can be read.
 */
async function readCodexUsage(token) {
  const usage = await fetchJson(CODEX_USAGE_URL, token);
  const rateLimit = usage?.rate_limit;
  const windows = [
    toWindow("5h", rateLimit?.primary_window?.used_percent, epochToDate(rateLimit?.primary_window?.reset_at)),
    toWindow("7d", rateLimit?.secondary_window?.used_percent, epochToDate(rateLimit?.secondary_window?.reset_at)),
  ].filter(Boolean);

  if (windows.length === 0) {
    throw new ProviderError("the usage response carried no rate-limit windows");
  }
  return { plan: capitalize(usage?.plan_type), windows };
}

/**
 * A window, or nothing when the provider did not report its utilization.
 * @param {string} label - window length.
 * @param {unknown} percent - consumed share as reported.
 * @param {Date | undefined} resetsAt - rollover moment, when disclosed.
 * @returns {Window | null} the normalized window.
 */
function toWindow(label, percent, resetsAt) {
  if (typeof percent !== "number" || Number.isNaN(percent)) return null;
  return { label, percent, resetsAt };
}

function parseMoment(value) {
  if (typeof value !== "string") return undefined;
  const moment = new Date(value);
  return Number.isNaN(moment.getTime()) ? undefined : moment;
}

function epochToDate(seconds) {
  if (typeof seconds !== "number" || Number.isNaN(seconds)) return undefined;
  const moment = new Date(seconds * 1000);
  return Number.isNaN(moment.getTime()) ? undefined : moment;
}

function capitalize(value) {
  return typeof value === "string" && value.length > 0
    ? value[0].toUpperCase() + value.slice(1)
    : undefined;
}

/** A short cause description that never leaks a token or a stack. */
function describe(cause) {
  if (cause?.name === "TimeoutError") return `no answer in ${REQUEST_TIMEOUT_MS / 1000}s`;
  return cause?.code ?? cause?.name ?? String(cause?.message ?? cause);
}

function formatMoment(moment) {
  return moment.toLocaleString(undefined, {
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  });
}

/** `2h 51m` / `3d 20h` / `40s`, or nothing once the moment has passed. */
function formatDistance(moment) {
  const seconds = Math.round((moment.getTime() - Date.now()) / 1000);
  if (seconds <= 0) return undefined;
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  if (days > 0) return `${days}d ${hours}h`;
  if (hours > 0) return `${hours}h ${minutes}m`;
  return minutes > 0 ? `${minutes}m` : `${seconds}s`;
}

function renderBar(percent) {
  const filled = Math.max(0, Math.min(BAR_CELLS, Math.round((percent / 100) * BAR_CELLS)));
  return "\u2588".repeat(filled) + "\u2591".repeat(BAR_CELLS - filled);
}

/**
 * One window line: bar, rounded percentage, and when it rolls over.
 * @param {Window} window - the window to render.
 * @returns {string} an indented report line.
 */
function renderWindow(window) {
  const percent = `${Math.round(window.percent)}%`.padStart(4);
  const exhausted = window.percent >= 100 ? "limit reached, " : "";
  const distance = window.resetsAt ? formatDistance(window.resetsAt) : undefined;
  const reset = window.resetsAt
    ? `${exhausted}resets ${formatMoment(window.resetsAt)}${distance ? ` (in ${distance})` : ""}`
    : `${exhausted}reset time not reported`;
  return `  ${window.label.padEnd(3)} ${renderBar(window.percent)} ${percent}  ${reset}`;
}

/**
 * Poll one provider, converting every failure into a readable line.
 * @param {Provider} provider - subscription to report on.
 * @returns {Promise<{provider: Provider, usage?: Usage, failure?: string}>} the outcome.
 */
async function pollProvider(provider) {
  try {
    return { provider, usage: await provider.read(readAccessToken(provider)) };
  } catch (error) {
    return {
      provider,
      failure: error instanceof ProviderError ? error.message : describe(error),
    };
  }
}

function renderOutcome({ provider, usage, failure }) {
  if (!usage) return `${provider.label}: ${failure}`;
  const heading = usage.plan ? `${provider.label} (${usage.plan})` : provider.label;
  return [heading, ...usage.windows.map(renderWindow)].join("\n");
}

/**
 * Report every provider, succeeding when at least one answered. A run where
 * both fail is an error whose text still explains each provider separately.
 * @returns {Promise<{kind: 'success' | 'error', text: string}>} the rendered report.
 */
async function executeSubscriptionLimits() {
  const outcomes = await Promise.all(PROVIDERS.map(pollProvider));
  return {
    kind: outcomes.some((outcome) => outcome.usage) ? "success" : "error",
    text: outcomes.map(renderOutcome).join("\n"),
  };
}

/** Register the global `/subscription-limits` command. */
function apply(ctx) {
  ctx.commands.register({
    name: "subscription-limits",
    description: "show remaining Claude and Codex subscription limits",
    recordInput: false,
    handler: () => executeSubscriptionLimits(),
  });
}

export { apply, executeSubscriptionLimits, inject, name };
