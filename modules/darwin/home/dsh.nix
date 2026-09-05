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
# Both TUI profiles carry dsh-superclaude, which adds one command --
# `/sc <command> [argument]` -- and nothing else: the SuperClaude command
# briefs, vendored, expanded into the agent's next turn. It is ours
# (codeberg.org/sacrilegewastaken/dsh-superclaude), pinned by commit below,
# and installed by the launcher because cloning it needs the user's ssh key.
#
# Two TUI profiles, one launcher each. `dsht` runs the `dsh-tui` profile and
# is the everyday one. `dsht-gsd` runs the `dsht-gsd` profile, which is the
# same TUI plus the GSD (Git Ship Done) bundle. The split exists because a
# bundle is not an optional tool set: GSD's patch layer overrides the
# agent-loop row, so every session in a profile carrying it boots into the
# phase loop. GSD also drives git directly and gates on the current branch
# name, which is wrong for a Sapling checkout (detached HEAD) -- see
# dshGsdEnsure. Keeping it behind its own command makes the phase loop
# something chosen, and leaves `dsht` a plain agent.
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

  # The `/subscription-limits` slash command. Loaded straight from its store
  # path, so it needs no pnpm install into a profile.
  subscriptionLimitsCommand =
    pkgs.callPackage ../../../pkgs/dsh-command-subscription-limits { };

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

  # Shared: bring the profile named by the argument up to a working TUI -- the
  # plugin pairing pnpm refuses and npm installs (see the header comment), the
  # subscription adapters, and the two patches. The plugin's own launcher
  # performs the same bootstrap on first run.
  #
  # Parametrized because there is more than one TUI profile now: `dsht` runs
  # `dsh-tui` and `dsht-gsd` runs `dsht-gsd`, and they differ in exactly one
  # thing -- whether the GSD bundle is layered on top. A Nix function for the
  # same reason dshGsdEnsure is one: the name is known at eval time, and these
  # blocks are spliced text rather than shell functions that could take an
  # argument.
  dshTuiEnsureIn = profName: ''
    PROF="$HOME/.dsh/profiles/${profName}"
    if [ ! -d "$PROF/node_modules/@deepseek-harness-tui/dsh-tui" ]; then
      echo "${profName}: first run -- creating the $PROF profile..."
      node --expose-internals "$BIN" plugin --profile ${profName} add @deepseek-harness-tui/dsh-tui@0.10.0-beta.5
    fi
    if [ ! -d "$PROF/node_modules/dsh-llm-subscription" ]; then
      echo "${profName}: installing dsh-llm-subscription (Claude/Gemini/Qwen via your CLIs)..."
      node --expose-internals "$BIN" plugin --profile ${profName} add dsh-llm-subscription@0.1.4
    fi
    ${dshLlmSubPatch}
    ${dshTuiDecstbmPatch}
    ${dshSuperClaudeEnsure profName}
  '';

  # Shared: install the SuperClaude command bundle into the profile named by
  # the argument, giving that profile `/sc <command> [argument]`.
  #
  # Not on npm -- it is ours (codeberg), so the spec is the git URL and pnpm
  # clones it. Pinned to a commit rather than a branch: an install that
  # silently follows `main` is not a configuration, and the existence check
  # below would never notice it moved anyway. Bumping is an edit here plus one
  # `dsh plugin --profile <p> add <url>#<sha>` (or removing the directory), the
  # same shape as GSD's version pin.
  #
  # The clone needs the user's ssh key. It runs from the launcher rather than
  # from activation for exactly that reason: a key behind a passphrase prompt
  # belongs in a terminal the user is sitting at, not in a home-manager
  # switch.
  dshSuperClaudeEnsure = profName: ''
    if [ ! -d "$HOME/.dsh/profiles/${profName}/node_modules/dsh-superclaude" ]; then
      echo "${profName}: installing dsh-superclaude (the /sc command set)..."
      node --expose-internals "$BIN" plugin --profile "${profName}" add \
        "git+ssh://git@codeberg.org/sacrilegewastaken/dsh-superclaude.git#${dshSuperClaudeRev}" \
        || echo "${profName}: dsh-superclaude not installed (offline, or no ssh key?) -- /sc will be absent" >&2
    fi
  '';

  # The pinned dsh-superclaude commit. Bump deliberately; see the ensure block.
  dshSuperClaudeRev = "2a262ac10bc75adbc573bc01fb72431d01dae2a8";

  # `dsht` / `dsh-tui`: the plain TUI. The removal is the migration for a
  # profile that carried GSD before the split; it is a no-op afterwards.
  dshTuiEnsure = (dshTuiEnsureIn "dsh-tui") + (dshGsdRemove "dsh-tui");

  # `dsht-gsd`: the same TUI with the GSD phase loop layered on top.
  dshGsdTuiEnsure = (dshTuiEnsureIn "dsht-gsd") + (dshGsdEnsure "dsht-gsd");

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

  # Shared: disable dsh-tui's DECSTBM hardware-scroll fast path inside zellij,
  # where it corrupts the transcript. In alt-screen the renderer shifts the
  # ScrollBox with `CSI top;bot r` + `CSI n S/T` and then repaints only the
  # rows that scrolled in. zellij's `CSI T` (grid.rs rotate_scroll_region_up)
  # moves rows only while the cursor sits inside the scroll region, and its
  # `CSI r` does not home the cursor outside origin mode -- but the renderer
  # parks the cursor on the last screen row, below every ScrollBox. The shift
  # is dropped, the diff assumes it happened, and stale rows survive on every
  # scroll-up frame (tearing, leftover lines).
  #
  # The gate that should have caught this is isDecstbmSafe(): it excludes tmux
  # and JediTerm but not zellij, and zellij forwards KITTY_WINDOW_ID into the
  # pane, so detection concludes it is talking to kitty directly. Only the
  # DECSTBM path is withdrawn -- zellij implements DEC 2026 properly, so
  # BSU/ESU stay on and frames remain atomic.
  #
  # Sent upstream as ccch1mneyyy/dsh-TUI#766 "fix(ink): disable DECSTBM
  # hardware scroll inside zellij"; drop this block once a release carries it.
  # Idempotent, and loud-but-harmless if a future version changes the body.
  dshTuiDecstbmPatch = ''
    _f="$PROF/node_modules/@deepseek-harness-tui/dsh-tui/lib/types/ink/terminal.js"
    if [ -f "$_f" ] && ! grep -q "process.env.ZELLIJ" "$_f"; then
      "${pkgs.python3}"/bin/python3 - "$_f" <<'PY'
    import sys

    path = sys.argv[1]
    source = open(path).read()
    old = "return SYNC_OUTPUT_SUPPORTED && !isJetBrainsIdeTerminal();"
    new = "return SYNC_OUTPUT_SUPPORTED && !isJetBrainsIdeTerminal() && !process.env.ZELLIJ;"
    found = source.count(old)
    if found != 1:
        print("dsh-tui: isDecstbmSafe body not found (%d matches) -- zellij scroll patch skipped" % found, file=sys.stderr)
        raise SystemExit(0)
    open(path, "w").write(source.replace(old, new))
    print("dsh-tui: DECSTBM hardware scroll disabled under zellij")
    PY
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
  # workflow -- do not let it own commits here. That is also why it no longer
  # sits in the everyday TUI profile: a bundle that overrides the agent loop
  # cannot be ignored session by session, and its branch gate fails outright
  # on the detached HEAD that Sapling leaves behind. It has its own profile
  # and its own launcher (`dsht-gsd`) instead, so choosing the phase loop is
  # choosing which command to type.
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

  # Shared: take the GSD bundle back out of the profile named by the argument.
  # `dsh plugin` forwards to pnpm and then reconciles `dsh.profile.bundles`
  # from the installed state, so one `remove` drops both the dependency and
  # the layer -- deleting the directory by hand would leave the profile
  # manifest naming a bundle that is no longer there. Idempotent: the profile
  # that never had it is not touched.
  dshGsdRemove = profName: ''
    if [ -d "$HOME/.dsh/profiles/${profName}/node_modules/@dsh-gsd/bundle" ]; then
      echo "dsh: removing the GSD bundle from the ${profName} profile (it lives in dsht-gsd now)..."
      node --expose-internals "$BIN" plugin --profile "${profName}" remove @dsh-gsd/bundle
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

  # The TUI runs with the file sandbox disabled, by explicit decision: `dsht`
  # is the surface used for work that reaches outside the session workspace
  # (GPG keyring, ~/.ssh, keychain-backed pushes), where a per-command
  # escalation prompt interrupts the flow. dsh-base defaults the row to
  # `mode: process.env.DSH_PERMISSION_MODE ?? 'workspace-write'`, so exporting
  # the variable is the whole mechanism.
  #
  # Scoped to the TUI on purpose: `dsh web` keeps the workspace-write default,
  # so this is not a global relaxation. The agent's blast radius here is the
  # entire home directory -- including files no revert brings back -- so keep
  # the risky, unattended work on the web profile.
  #
  # Narrowable per invocation: `DSH_PERMISSION_MODE=workspace-write dsht`.
  dshTuiPermissionMode = ''
    export DSH_PERMISSION_MODE="''${DSH_PERMISSION_MODE:-danger-full-access}"
  '';

  dshTuiLauncher = pkgs.writeShellScriptBin "dsh-tui" ''
    ${dshBootstrap}
    ${dshTuiEnsure}
    ${dshTuiPermissionMode}
    exec node --expose-internals "$BIN" --profile dsh-tui "$@"
  '';

  dshtShortcut = pkgs.writeShellScriptBin "dsht" ''
    ${dshBootstrap}
    ${dshTuiEnsure}
    ${dshTuiPermissionMode}
    exec node --expose-internals "$BIN" --profile dsh-tui "$@"
  '';

  # The GSD front end: same TUI, same permissions, its own profile. Separate
  # rather than a flag on `dsht`, because a bundle is a property of the
  # profile -- GSD's patch layer overrides the agent-loop row, so a session
  # either boots into the phase loop or does not, and nothing decided at the
  # command line can change that afterwards.
  #
  # The profile self-initializes here on first launch, like the TUI one, and
  # is deliberately NOT created during activation: a machine that never runs
  # this command should not pay for a bundle it does not use.
  dshtGsdShortcut = pkgs.writeShellScriptBin "dsht-gsd" ''
    ${dshBootstrap}
    ${dshGsdTuiEnsure}
    ${dshTuiPermissionMode}
    exec node --expose-internals "$BIN" --profile dsht-gsd "$@"
  '';

  # Explicit (re)install / repair: also re-runs when the plugin is already
  # present, so it doubles as the update path.
  dshTuiSetupScript = pkgs.writeShellScriptBin "dsh-tui-setup" ''
    set -euo pipefail
    ${dshBootstrap}
    echo "Installing the dsh-tui plugin into the 'dsh-tui' profile..."
    node --expose-internals "$BIN" plugin --profile dsh-tui add @deepseek-harness-tui/dsh-tui@0.10.0-beta.5
    PROF="$HOME/.dsh/profiles/dsh-tui"
    ${dshTuiDecstbmPatch}
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
  #   * an insert adding all six MCP servers, plus the local
  #     `/subscription-limits` command plugin. A plugin row's `name` is an
  #     import specifier resolved against the profile root, so an absolute
  #     store path mounts a plugin that lives outside any node_modules.
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
        - id: command-subscription-limits
          name: '${subscriptionLimitsCommand}/lib/index.js'
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
  home.packages = [ dshLauncher dshTuiLauncher dshtShortcut dshtGsdShortcut dshTuiSetupScript ];

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

  # First-run self-setup of the GSD workflow bundle in the web profile. The
  # TUI side is not here any more: `dsh-tui` has GSD taken out of it by
  # setupDshTui above, and the `dsht-gsd` profile is built by its own launcher
  # on first use rather than by every activation.
  home.activation.setupDshGsd = lib.hm.dag.entryAfter [ "setupDshLlmSub" ] ''
    (
      ${dshBootstrap}
      ${dshGsdEnsure "web"}
    ) || echo "warning: GSD bundle not set up (offline?); see 'dsh web'" >&2 || true
  '';

  # dsh reads a GLOBAL instruction file from its harness home:
  # ~/.dsh/AGENTS.md (agent-instructions only honors AGENTS.md there). Link
  # it to Claude Code's global CLAUDE.md so dsh and Claude Code share the
  # same global instructions. The simlink target is the user's Claude Code
  # global file (exists from their claude login; if absent, home-manager's
  # dangling link is acceptable -- dsh simply sees no global file).
  home.file.".dsh/AGENTS.md".source = "/Users/${username}/.claude/CLAUDE.md";
}