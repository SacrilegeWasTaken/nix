# DeepSeek Harness (`dsh`, https://github.com/deepseek-ai/deepseek-harness) and
# its MCP server configuration: context7, sequential-thinking, playwright,
# serena, tavily, lldb -- the same set wired up for Claude Code in
# claude-code.nix.
#
# dsh has no nixpkgs derivation yet (developer preview, breaking changes
# expected); this wrapper runs the npm distribution under `node
# --expose-internals` (required by its HMR service, see below). MCP servers
# are not read from a JSON file like Claude
# Code; dsh loads a Cordis YAML "patch" layer at $DSH_HOME/cordis.patch.yml
# (default $DSH_HOME is ~/.dsh) via the @deepseek-ai/dsh-mcp-client plugin.
#
# Tavily requires TAVILY_API_KEY. Free key: https://app.tavily.com
# Set it in fish: set -Ux TAVILY_API_KEY "tvly-..."
# dsh strips ambient vars that look like credentials before starting an MCP
# child, so the key is re-added explicitly via a `!!js` env expression below.
#
# An interactive TUI (dsh-tui) was tried and removed: the plugin ecosystem
# around it is not yet compatible with the current core -- dsh 0.1.2-alpha.4
# removed the Session.events getter the plugin's transcript replay still
# calls ("events is not iterable"), and the plugin releases that track the
# newer core cannot be installed (broken peer ranges). Web is the supported
# interactive surface right now: `dsh web` -> http://127.0.0.1:3080.
#
# Plain `npx -y @deepseek-ai/dsh@latest web` no longer boots even by itself:
# the current core mounts cordis-plugin-hmr in live profiles, and its HMR
# service refuses to start without `--expose-internals`, which Node forbids
# passing via NODE_OPTIONS (so it must be a real CLI flag). The launcher
# below therefore primes the npx cache once, then runs the cached bin with
# `node --expose-internals`. Verified: web boots, HTTP 200 auth page (401
# without the token is the expected pre-auth answer), no crash after 45s.
{ config, pkgs, lib, ... }:

let
  lldbMcpServer = pkgs.callPackage ../../../pkgs/lldb-mcp.nix { };

  dshLauncher = pkgs.writeShellScriptBin "dsh" ''
    BIN="$(ls -t "$HOME"/.npm/_npx/*/node_modules/@deepseek-ai/dsh/lib/bin.js 2>/dev/null | head -1)"
    if [ -z "$BIN" ]; then
      npx -y @deepseek-ai/dsh@latest --version >/dev/null 2>&1
      BIN="$(ls -t "$HOME"/.npm/_npx/*/node_modules/@deepseek-ai/dsh/lib/bin.js 2>/dev/null | head -1)"
    fi
    exec node --expose-internals "$BIN" "$@"
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
  home.packages = [ dshLauncher ];

  home.activation.setupDshMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupDshMcpScript}
  '';
}
