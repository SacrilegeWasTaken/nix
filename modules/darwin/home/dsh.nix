# DeepSeek Harness (`dsh`, https://github.com/deepseek-ai/deepseek-harness) and
# its MCP server configuration: context7, sequential-thinking, playwright,
# serena, tavily, lldb -- the same set wired up for Claude Code in
# claude-code.nix.
#
# dsh has no nixpkgs derivation yet (developer preview, breaking changes
# expected). Both the web and the TUI surfaces require the npm distribution
# to run under `node --expose-internals`: the current core mounts
# cordis-plugin-hmr in live profiles, and its HMR service refuses to start
# without that flag, which Node forbids passing via NODE_OPTIONS (it must be
# a real CLI flag). The launchers below therefore prime the npx cache once,
# then run the cached dsh bin with `node --expose-internals`.
#
# MCP servers are not read from a JSON file like Claude Code; dsh loads a
# Cordis YAML "patch" layer at $DSH_HOME/cordis.patch.yml (default $DSH_HOME
# is ~/.dsh) via the @deepseek-ai/dsh-mcp-client plugin.
#
# Tavily requires TAVILY_API_KEY. Free key: https://app.tavily.com
# Set it in fish: set -Ux TAVILY_API_KEY "tvly-..."
# dsh strips ambient vars that look like credentials before starting an MCP
# child, so the key is re-added explicitly via a `!!js` env expression below.
#
# ---- TUI front end (@deepseek-harness-tui/dsh-tui, THIRD-PARTY) ----
# dsh ships no terminal UI of its own (only web/headless/sdk/acp profiles).
# This wraps the community dsh-tui (github.com/ccch1mneyyy/dsh-TUI). Earlier
# attempts got bogged down in version archaeology; the working pairing is the
# one pnpm REFUSED to install and npm installs cleanly:
#   core @deepseek-ai/dsh@0.1.2-rc.1  +  plugin @deepseek-harness-tui/dsh-tui@0.10.0-beta.5
# The plugin's own launcher (bin/dsh-tui.js) auto-creates the profile on
# first run via `dsh plugin --profile dsh-tui add <pkg>@<ver>`, so setup only
# needs to prime the npx cache and let that bootstrap happen. Verified
# end-to-end: full plugin tree boots, all six MCP servers come up, the TUI
# process stays alive past the boot window with zero crash traces.
#
# Any dsh plugin runs with the harness's full access (files, network,
# credentials) and has not been audited. The profile self-initializes on
# first launch and, when absent, during home-manager activation -- no manual
# step needed. dsh-tui-setup remains for repairs/updates.
#
# Model provider is the llm-pi-ai 'openrouter' route the user declares in
# $DSH_HOME/settings.yaml; OPENROUTER_API_KEY reaches the shell via sops
# (secrets/default.yaml -> /run/secrets/openrouter-api-key -> fish).
#
# Which model a fresh session starts on is left to dsh-base's own
# composition default (deepseek-v4-flash): its adapter is the one route
# present in every profile, and the `/model` picker persists a per-user
# choice over it in $DSH_HOME/settings.yaml.
#
# Codex subscriptions (ChatGPT/Codex) come from the third-party
# dsh-codex-subscription plugin, installed into the WEB profile only: the TUI
# profile would double-register core's built-in "openai-codex" LLM adapter
# and fail to boot. Login (ChatGPT OAuth) and quota UI happen in the web app:
# `dsh web` -> Settings -> Codex.
#
# Claude (and Gemini/Qwen) come from the third-party dsh-llm-subscription
# plugin, installed in BOTH the web and the TUI profiles (it registers NEW
# adapters claude/gemini/qwen, so no adapter collision -- verified with an
# isolated TUI boot; unlike codex, which re-registers the core's existing
# "openai-codex" and must stay web-only). It shells out to the user's own
# `claude`/`agy`/`ollama` CLIs -- the low-risk variety of bridging a
# subscription -- and needs `claude login` to have run once. Models
# (claude/haiku/sonnet/opus/fable, Gemini tiers, local qwen3.5) then appear
# in the web AND TUI model pickers.
{ config, pkgs, lib, username, ... }:

let
  lldbMcpServer = pkgs.callPackage ../../../pkgs/lldb-mcp.nix { };

  # Shared: locate the newest npx-cached dsh core (priming once if absent)
  # and leave $BIN set, or die with a hint. `~` is expanded at run time
  # because these scripts are immutable in the nix store.
  dshBootstrap = ''
    BIN="$(ls -t "$HOME"/.npm/_npx/*/node_modules/@deepseek-ai/dsh/lib/bin.js 2>/dev/null | head -1)"
    if [ -z "$BIN" ]; then
      npx -y @deepseek-ai/dsh@0.1.2-rc.1 --version >/dev/null 2>&1
      BIN="$(ls -t "$HOME"/.npm/_npx/*/node_modules/@deepseek-ai/dsh/lib/bin.js 2>/dev/null | head -1)"
    fi
    if [ -z "$BIN" ]; then
      echo "dsh: could not locate the @deepseek-ai/dsh runtime (offline first run?)" >&2
      exit 1
    fi
  '';

  # Shared: if the dsh-tui profile does not yet contain the plugin, create it
  # with the pairing pnpm refuses but npm installs (see the header comment).
  # The plugin's own launcher performs the same bootstrap on first run.
  dshTuiEnsure = ''
    PROF="$HOME/.dsh/profiles/dsh-tui"
    if [ ! -d "$PROF/node_modules/@deepseek-harness-tui/dsh-tui" ]; then
      echo "dsh-tui: first run -- creating the $PROF profile..."
      node --expose-internals "$BIN" plugin --profile dsh-tui add @deepseek-harness-tui/dsh-tui@0.10.0-beta.5
    fi
    if [ ! -d "$PROF/node_modules/dsh-llm-subscription" ]; then
      echo "dsh-tui: installing dsh-llm-subscription (Claude/Gemini/Qwen via your CLIs)..."
      node --expose-internals "$BIN" plugin --profile dsh-tui add dsh-llm-subscription@0.1.4
    fi
    ${dshLlmSubPatch}
    ${dshGsdEnsure "dsh-tui"}
  '';

  # Shared: patch dsh-llm-subscription's advertised contextWindow from the
  # hardcoded 200k to 1M so dsh lets sessions grow to Claude's real ceiling.
  # The plugin has no config knob for this; the value lives in its lib, so we
  # rewrite it after install. Idempotent (only touches files still at 200k).
  # Reads the profile path from $PROF, which every call site sets just
  # before invoking this block (not a real shell function, so it cannot
  # take a positional argument -- see the dshGsdEnsure comment below).
  dshLlmSubPatch = ''
    _f="$PROF/node_modules/dsh-llm-subscription/lib/index.js"
    if [ -f "$_f" ] && grep -q "contextWindow: 200000" "$_f"; then
      "${pkgs.python3}"/bin/python3 - "$_f" <<'PY'
    import sys
    p = sys.argv[1]
    s = open(p).read()
    s = s.replace("contextWindow: 200000", "contextWindow: 1000000")
    open(p, "w").write(s)
    PY
      echo "dsh-llm-subscription: bumped contextWindow to 1M ($PROF)"
    fi
  '';

  # Give Codex's GPT-5.6 variants their supported 1M-token window on first
  # setup. Preserve an explicit choice made later in the Codex settings UI.
  dshCodexContextDefault = ''
    "${pkgs.python3}"/bin/python3 - "$HOME/.dsh/settings.yaml" <<'PY'
    from pathlib import Path
    import re
    import sys

    path = Path(sys.argv[1])
    text = path.read_text() if path.exists() else ""
    section = re.search(r"(?m)^codex-subscription:\s*(?:#.*)?$", text)

    if section is None:
        suffix = "" if not text or text.endswith("\n") else "\n"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(f"{text}{suffix}codex-subscription:\n  contextMode: extended\n")
    else:
        tail = text[section.end():]
        next_section = re.search(r"(?m)^[^\s#][^:\n]*:\s*", tail)
        body_end = section.end() + (next_section.start() if next_section else len(tail))
        body = text[section.end():body_end]
        if not re.search(r"(?m)^\s+contextMode:\s*", body):
            text = f"{text[:section.end()]}\n  contextMode: extended{text[section.end():]}"
            path.write_text(text)
    PY
  '';

  # Shared: install dsh-codex-subscription into the WEB profile when missing.
  # It cannot go into the TUI profile -- dsh-tui's own composition already
  # registers an "openai-codex" LLM adapter and the plugin would double-
  # register it ("adapter for provider openai-codex is already registered").
  # Login and usage happen in the web UI: dsh web -> Settings -> Codex.
  dshCodexEnsure = ''
    PROF="$HOME/.dsh/profiles/web"
    if [ ! -d "$PROF/node_modules/dsh-codex-subscription" ]; then
      echo "dsh: installing dsh-codex-subscription into the web profile..."
      node --expose-internals "$BIN" plugin --profile web add dsh-codex-subscription@1.13.1
    fi
    ${dshCodexContextDefault}
  '';

  # Shared: install dsh-llm-subscription (Claude/Gemini/Qwen via the local
  # claude/agy/ollama CLIs) into the WEB profile when missing. Unlike
  # codex it is also safe in the TUI profile: it registers NEW LLM provider
  # adapters (claude/gemini/qwen) rather than re-registering an existing
  # one, so no "adapter for provider ... already registered" collision
  # (verified with an isolated TUI boot). Needs `claude login` once.
  dshLlmSubEnsure = ''
    PROF="$HOME/.dsh/profiles/web"
    if [ ! -d "$PROF/node_modules/dsh-llm-subscription" ]; then
      echo "dsh: installing dsh-llm-subscription into the web profile..."
      node --expose-internals "$BIN" plugin --profile web add dsh-llm-subscription@0.1.4
    fi
    ${dshLlmSubPatch}
  '';

  # Shared: install the GSD (Git Ship Done) bundle into the profile named by
  # $1. `dsh plugin` appends it last in the profile's bundle list, so its
  # patch layer lands after the profile's own rows; GSD's patch overrides the
  # agent-loop row, which makes the phase loop
  # (spec -> discuss -> plan -> execute -> verify -> ship) the default
  # behavior of every session in that profile, not an extra tool set.
  #
  # GSD drives `git` directly (phase branches, commits, best-effort pushes)
  # and `gh pr create` on ship, so it does not follow this repo's Sapling
  # workflow -- do not let it own commits here.
  # A Nix function, not a shell function: the profile name is known at eval
  # time for every call site, so it is spliced in literally here rather than
  # read from a shell positional parameter. `${dshGsdEnsure} dsh-tui` (the
  # previous shape) is plain string concatenation, not a function call --
  # the trailing "dsh-tui"/"web" text just became a stray extra command
  # appended to the script, and since dsh-tui's own launcher is also named
  # "dsh-tui", that stray line recursively re-invoked itself.
  dshGsdEnsure = profName: ''
    if [ ! -d "$HOME/.dsh/profiles/${profName}/node_modules/@dsh-gsd/bundle" ]; then
      echo "dsh: installing the GSD bundle into the ${profName} profile..."
      node --expose-internals "$BIN" plugin --profile "${profName}" add @dsh-gsd/bundle@3.0.0
    fi
  '';

  dshLauncher = pkgs.writeShellScriptBin "dsh" ''
    ${dshBootstrap}
    if [ "$#" -ge 1 ] && [ "$1" = "web" ]; then
      ${dshCodexEnsure}
      ${dshLlmSubEnsure}
      ${dshGsdEnsure "web"}
    fi
    exec node --expose-internals "$BIN" "$@"
  '';

  dshTuiLauncher = pkgs.writeShellScriptBin "dsh-tui" ''
    ${dshBootstrap}
    ${dshTuiEnsure}
    exec node --expose-internals "$BIN" --profile dsh-tui "$@"
  '';

  dshtShortcut = pkgs.writeShellScriptBin "dsht" ''
    ${dshBootstrap}
    ${dshTuiEnsure}
    exec node --expose-internals "$BIN" --profile dsh-tui "$@"
  '';

  # Explicit (re)install / repair: also re-runs when the plugin is already
  # present, so it doubles as the update path.
  dshTuiSetupScript = pkgs.writeShellScriptBin "dsh-tui-setup" ''
    set -euo pipefail
    ${dshBootstrap}
    echo "Installing the dsh-tui plugin into the 'dsh-tui' profile..."
    node --expose-internals "$BIN" plugin --profile dsh-tui add @deepseek-harness-tui/dsh-tui@0.10.0-beta.5
    echo ""
    echo "Done! Start it with:  dsh-tui   (alias: dsht)"
    echo "Resume a session:     dsh-tui --resume <session-id>"
    echo ""
    echo "Model provider: llm-pi-ai 'openrouter' (OPENROUTER_API_KEY via sops)."
  '';

  # Single managed patch block spliced into ~/.dsh/cordis.patch.yml (see
  # setupDshMcp below). Two kinds of patches, applied to every profile:
  #   * a replace that re-enables core's dsh-agent-instructions, which dsh-base
  #     ships disabled:true. That plugin is what makes dsh read AGENTS.md /
  #     CLAUDE.md from the workspace (and AGENTS.md from the harness home), so
  #     without it dsh never sees CLAUDE.md files.
  #   * an insert adding all six MCP servers.
  #
  # Each stdio server is wrapped in /bin/sh so its stderr -- startup
  # banners, npm/uvx progress, serena's INFO log -- is appended to a per-
  # server file under ~/.dsh/logs instead of the terminal, where it would
  # overwrite the TUI. dsh-mcp-client keeps the child's stderr on the TTY
  # (no redirect option), and stdout is the MCP protocol, so this shell
  # wrapper is the only clean way to silence the noise. HOME is not among
  # the ambient vars the client scrubs, so $HOME expands in the wrapper.
  dshPatchBlock = pkgs.writeText "dsh-cordis-patch.yml" ''
    - id: agent-instructions
      config:
        maxBytes: 65536
      disabled: false
    - insert:
        - id: mcp-context7
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: context7
            transport: stdio
            command: /bin/sh
            args: ['-c', 'mkdir -p "$HOME/.dsh/logs" && exec npx -y @upstash/context7-mcp@latest 2>>"$HOME/.dsh/logs/context7.log"']
            env: {}
        - id: mcp-sequential-thinking
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: sequential-thinking
            transport: stdio
            command: /bin/sh
            args: ['-c', 'mkdir -p "$HOME/.dsh/logs" && exec npx -y @modelcontextprotocol/server-sequential-thinking 2>>"$HOME/.dsh/logs/sequential-thinking.log"']
            env: {}
        - id: mcp-playwright
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: playwright
            transport: stdio
            command: /bin/sh
            args: ['-c', 'mkdir -p "$HOME/.dsh/logs" && exec npx -y @playwright/mcp@latest 2>>"$HOME/.dsh/logs/playwright.log"']
            env: {}
        - id: mcp-serena
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: serena
            transport: stdio
            command: /bin/sh
            args: ['-c', 'mkdir -p "$HOME/.dsh/logs" && exec uvx --from git+https://github.com/oraios/serena serena start-mcp-server 2>>"$HOME/.dsh/logs/serena.log"']
            env: {}
        - id: mcp-tavily
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: tavily
            transport: stdio
            command: /bin/sh
            args: ['-c', 'mkdir -p "$HOME/.dsh/logs" && exec npx -y tavily-mcp@latest 2>>"$HOME/.dsh/logs/tavily.log"']
            env:
              TAVILY_API_KEY: !!js process.env.TAVILY_API_KEY
        - id: mcp-lldb
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: lldb
            transport: stdio
            command: /bin/sh
            args: ['-c', 'mkdir -p "$HOME/.dsh/logs" && exec ${lldbMcpServer}/bin/lldb-mcp-server 2>>"$HOME/.dsh/logs/lldb.log"']
            env: {}
  '';

  # Splices dshPatchBlock into ~/.dsh/cordis.patch.yml between marker
  # comments, replacing a previous run's block in place instead of
  # duplicating entries or clobbering any patches the user added by hand.
  setupDshMcpScript = pkgs.writeScript "setup-dsh-mcp" ''
    #!${pkgs.python3}/bin/python3
    import os

    dsh_home = os.path.expanduser("~/.dsh")
    os.makedirs(dsh_home, exist_ok=True)
    patch_path = os.path.join(dsh_home, "cordis.patch.yml")

    BEGIN = "# >>> nix-managed dsh patch layer (Darwin flake: modules/darwin/home/dsh.nix) >>>"
    END = "# <<< nix-managed dsh patch layer <<<"

    with open("${dshPatchBlock}") as f:
        block = f.read().rstrip("\n")
    managed = BEGIN + "\n" + block + "\n" + END

    content = ""
    if os.path.exists(patch_path):
        with open(patch_path) as f:
            content = f.read()

    if BEGIN in content and END in content:
        pre, rest = content.split(BEGIN, 1)
        _, post = rest.split(END, 1)
        content = pre + managed + post
    else:
        sep = "\n" if content and not content.endswith("\n") else ""
        content = content + sep + managed + "\n"

    with open(patch_path, "w") as f:
        f.write(content)
  '';
in
lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = [ dshLauncher dshTuiLauncher dshtShortcut dshTuiSetupScript ];

  home.activation.setupDshMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupDshMcpScript}
  '';

  # First-run self-setup of the dsh-tui profile. No-op once the plugin is in
  # place; network-dependent, so failures warn instead of failing the build.
  home.activation.setupDshTui = lib.hm.dag.entryAfter [ "setupDshMcp" ] ''
    (
      ${dshBootstrap}
      ${dshTuiEnsure}
    ) || echo "warning: dsh-tui profile not set up (offline?); see dsh-tui-setup" >&2 || true
  '';

  # First-run self-setup of dsh-codex-subscription in the web profile.
  home.activation.setupDshCodex = lib.hm.dag.entryAfter [ "setupDshTui" ] ''
    (
      ${dshBootstrap}
      ${dshCodexEnsure}
    ) || echo "warning: dsh-codex-subscription not set up (offline?); see 'dsh web'" >&2 || true
  '';

  # First-run self-setup of dsh-llm-subscription in the web profile.
  home.activation.setupDshLlmSub = lib.hm.dag.entryAfter [ "setupDshCodex" ] ''
    (
      ${dshBootstrap}
      ${dshLlmSubEnsure}
    ) || echo "warning: dsh-llm-subscription not set up (offline?); see 'dsh web'" >&2 || true
  '';

  # First-run self-setup of the GSD workflow bundle in both standard profiles.
  home.activation.setupDshGsd = lib.hm.dag.entryAfter [ "setupDshLlmSub" ] ''
    (
      ${dshBootstrap}
      ${dshGsdEnsure "web"}
      ${dshGsdEnsure "dsh-tui"}
    ) || echo "warning: GSD bundle not set up (offline?); see 'dsh web' / 'dsht'" >&2 || true
  '';

  # dsh reads a GLOBAL instruction file from its harness home:
  # ~/.dsh/AGENTS.md (agent-instructions only honors AGENTS.md there). Link
  # it to Claude Code's global CLAUDE.md so dsh and Claude Code share the
  # same global instructions. The simlink target is the user's Claude Code
  # global file (exists from their claude login; if absent, home-manager's
  # dangling link is acceptable -- dsh simply sees no global file).
  home.file.".dsh/AGENTS.md".source = "/Users/${username}/.claude/CLAUDE.md";
}