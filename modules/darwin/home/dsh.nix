# DeepSeek Harness (`dsh`, https://github.com/deepseek-ai/deepseek-harness) and
# its MCP server configuration: context7, sequential-thinking, playwright,
# serena, tavily, lldb -- the same set wired up for Claude Code in
# claude-code.nix.
#
# dsh has no nixpkgs derivation yet (developer preview, breaking changes
# expected), so it is run the same way upstream recommends: `npx -y
# @deepseek-ai/dsh`. MCP servers are not read from a JSON file like Claude
# Code; dsh loads a Cordis YAML "patch" layer at $DSH_HOME/cordis.patch.yml
# (default $DSH_HOME is ~/.dsh) via the @deepseek-ai/dsh-mcp-client plugin.
#
# Tavily requires TAVILY_API_KEY. Free key: https://app.tavily.com
# Set it in fish: set -Ux TAVILY_API_KEY "tvly-..."
# dsh strips ambient vars that look like credentials before starting an MCP
# child, so the key is re-added explicitly via a `!!js` env expression below.
#
# ---- TUI front end (@deepseek-harness-tui/dsh-tui, THIRD-PARTY, not from
# deepseek-ai) ----
# dsh ships no terminal UI of its own (only web/headless/sdk/acp profiles).
# dsh-tui (github.com/ccch1mneyyy/dsh-TUI) is the community out-of-tree
# plugin bundle chosen for it -- picked over github.com/dsh-tui/dsh-tui
# (npm @dsh-tui/dsh-tui) because that one pins peer deps to the
# @deepseek-ai/dsh rc it shipped against (0.1.0-rc.6, 2026-08-14) and never
# updated, so its own bundled storage/session-projection-cache plugin rows
# now collide with the identically-named rows dsh-base gained since:
# `duplicate loader entry id: storage` at boot. This plugin's peer deps
# explicitly list 0.1.2-rc.1, the version our `dsh` wrapper runs.
#
# Like any dsh plugin it runs with the harness's full access (files,
# network, credentials) and has not been audited. Bootstrap is therefore a
# manual step (dsh-tui-setup) rather than something home-manager activation
# runs unattended -- same reasoning as the airis-mcp-setup /
# superclaude-setup helpers below.
# Needs DEEPSEEK_API_KEY in the environment; set it the same way as
# TAVILY_API_KEY above.
{ config, pkgs, lib, ... }:

let
  lldbMcpServer = pkgs.callPackage ../../../pkgs/lldb-mcp.nix { };

  dshLauncher = pkgs.writeShellScriptBin "dsh" ''
    exec npx -y @deepseek-ai/dsh@latest "$@"
  '';

  dshTuiLauncher = pkgs.writeShellScriptBin "dsh-tui" ''
    exec npx -y @deepseek-ai/dsh@latest --profile dsh-tui "$@"
  '';

  dshtShortcut = pkgs.writeShellScriptBin "dsht" ''
    exec npx -y @deepseek-ai/dsh@latest --profile dsh-tui "$@"
  '';

  dshTuiSetupScript = pkgs.writeShellScriptBin "dsh-tui-setup" ''
    set -euo pipefail
    echo "Installing dsh-tui into the 'dsh-tui' dsh profile..."
    npx -y @deepseek-ai/dsh@latest plugin --profile dsh-tui add @deepseek-harness-tui/dsh-tui

    echo ""
    echo "Done! Start it with:  dsh-tui"
    echo "Resume a session:     dsh-tui --resume <session-id>"
    echo ""
    echo "If the install fails with ERR_PNPM_IGNORED_BUILDS (pnpm >=11 blocks"
    echo "dependencies with install scripts, e.g. @google/genai, protobufjs),"
    echo "add them under allowBuilds in"
    echo "~/.dsh/profiles/dsh-tui/pnpm-workspace.yaml:"
    echo "  allowBuilds:"
    echo "    '@google/genai': false"
    echo "    protobufjs: false"
    echo "then re-run dsh-tui-setup."
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
}
