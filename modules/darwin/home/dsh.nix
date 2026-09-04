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
{ config, pkgs, lib, ... }:

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
  '';

  dshLauncher = pkgs.writeShellScriptBin "dsh" ''
    ${dshBootstrap}
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

  # Single Cordis "insert" patch adding all six servers, spliced into a
  # managed block inside ~/.dsh/cordis.patch.yml (see setupDshMcp below).
  mcpPatchBlock = pkgs.writeText "dsh-mcp-servers.cordis.yml" ''
    - insert:
        - id: mcp-context7
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: context7
            transport: stdio
            command: npx
            args: ['-y', '@upstash/context7-mcp@latest']
            env: {}
        - id: mcp-sequential-thinking
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: sequential-thinking
            transport: stdio
            command: npx
            args: ['-y', '@modelcontextprotocol/server-sequential-thinking']
            env: {}
        - id: mcp-playwright
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: playwright
            transport: stdio
            command: npx
            args: ['-y', '@playwright/mcp@latest']
            env: {}
        - id: mcp-serena
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: serena
            transport: stdio
            command: uvx
            args: ['--from', 'git+https://github.com/oraios/serena', 'serena', 'start-mcp-server']
            env: {}
        - id: mcp-tavily
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: tavily
            transport: stdio
            command: npx
            args: ['-y', 'tavily-mcp@latest']
            env:
              TAVILY_API_KEY: !!js process.env.TAVILY_API_KEY
        - id: mcp-lldb
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: lldb
            transport: stdio
            command: ${lldbMcpServer}/bin/lldb-mcp-server
            args: []
            env: {}
  '';

  # Splices mcpPatchBlock into ~/.dsh/cordis.patch.yml between marker
  # comments, replacing a previous run's block in place instead of
  # duplicating entries or clobbering any patches the user added by hand.
  setupDshMcpScript = pkgs.writeScript "setup-dsh-mcp" ''
    #!${pkgs.python3}/bin/python3
    import os

    dsh_home = os.path.expanduser("~/.dsh")
    os.makedirs(dsh_home, exist_ok=True)
    patch_path = os.path.join(dsh_home, "cordis.patch.yml")

    BEGIN = "# >>> nix-managed dsh MCP servers (Darwin flake: modules/darwin/home/dsh.nix) >>>"
    END = "# <<< nix-managed dsh MCP servers <<<"

    with open("${mcpPatchBlock}") as f:
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
}