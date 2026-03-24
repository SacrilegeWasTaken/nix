# Declarative MCP server configuration for Claude Code + SuperClaude.
# Servers: context7, sequential-thinking, playwright, serena, tavily.
#
# Two modes:
#   1. Direct (default) — activation merges server entries into ~/.claude.json.
#      Works immediately, no Docker dependency.
#   2. Gateway (opt-in) — run `airis-mcp-setup` to start the Docker-based
#      airis-mcp-gateway (recommended by SuperClaude for token efficiency).
#
# Tavily requires TAVILY_API_KEY.  Free key: https://app.tavily.com
# Set it in fish:  set -Ux TAVILY_API_KEY "tvly-..."
{ config, pkgs, lib, ... }:

let
  # ---- direct-mode server definitions (stdio, written to ~/.claude.json) ----
  mcpServers = {
    context7 = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp@latest" ];
      env = { };
    };
    "sequential-thinking" = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
      env = { };
    };
    playwright = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "@playwright/mcp@latest" ];
      env = { };
    };
    serena = {
      type = "stdio";
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/oraios/serena"
        "serena"
        "start-mcp-server"
        "--context"
        "ide-assistant"
      ];
      env = { };
    };
    tavily = {
      type = "stdio";
      command = "npx";
      args = [ "-y" "tavily-mcp@latest" ];
      env = { TAVILY_API_KEY = "$" + "{TAVILY_API_KEY}"; };
    };
  };

  mcpConfigFile = pkgs.writeText "claude-mcp-servers.json" (builtins.toJSON mcpServers);

  # Python script that merges our MCP entries into the mutable ~/.claude.json
  setupMcpScript = pkgs.writeScript "setup-claude-mcp" ''
    #!${pkgs.python3}/bin/python3
    import json, os, stat, sys

    config_path = os.path.expanduser("~/.claude.json")

    try:
        with open("${mcpConfigFile}") as f:
            mcp_servers = json.load(f)

        try:
            with open(config_path) as f:
                config = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            config = {}

        config.setdefault("mcpServers", {})
        config["mcpServers"].update(mcp_servers)

        with open(config_path, "w") as f:
            json.dump(config, f, indent=2, ensure_ascii=False)
        os.chmod(config_path, stat.S_IRUSR | stat.S_IWUSR)
    except Exception as e:
        print(f"Warning: Claude MCP setup skipped: {e}", file=sys.stderr)
  '';

  # ---- gateway-mode config (for airis-mcp-gateway Docker stack) ----
  gatewayMcpConfig = pkgs.writeText "airis-mcp-config.json" (builtins.toJSON {
    mcpServers = {
      "airis-mcp-gateway-control" = {
        command = "node";
        args = [ "/app/gateway-control/index.js" ];
        env = { API_URL = "http://localhost:8000"; };
        enabled = true;
        mode = "hot";
      };
      "airis-commands" = {
        command = "node";
        args = [ "/app/airis-commands/index.js" ];
        env = {
          MCP_CONFIG_PATH = "/app/mcp-config.json";
          PROFILES_DIR = "/app/profiles";
          HOST_CLAUDE_DIR = "/host-claude";
        };
        enabled = true;
        mode = "hot";
      };
      context7 = {
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp" ];
        env = { };
        enabled = true;
        mode = "cold";
      };
      "sequential-thinking" = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
        env = { };
        enabled = true;
        mode = "cold";
      };
      serena = {
        profile = "serena-remote";
        env = { };
        enabled = true;
        mode = "cold";
      };
      playwright = {
        command = "npx";
        args = [ "-y" "@playwright/mcp@latest" ];
        env = { };
        enabled = true;
        mode = "cold";
      };
      tavily = {
        command = "npx";
        args = [
          "-y"
          "mcp-remote"
          ("https://mcp.tavily.com/mcp/?tavilyApiKey=$" + "{TAVILY_API_KEY}")
        ];
        env = { };
        enabled = true;
        mode = "cold";
      };
    };
    profiles = {
      serena-local = {
        command = "uvx";
        args = [
          "--from"
          "git+https://github.com/oraios/serena"
          "serena"
          "start-mcp-server"
          "--transport"
          "stdio"
        ];
      };
      serena-remote = {
        command = "npx";
        args = [ "-y" "mcp-remote" "http://serena:8000/sse" "--allow-http" ];
      };
    };
    log.level = "info";
  });

  # Helper: clone/update airis-mcp-gateway and start the Docker stack
  airisSetupScript = pkgs.writeShellScriptBin "airis-mcp-setup" ''
    set -euo pipefail
    GATEWAY_DIR="$HOME/.local/share/airis-mcp-gateway"

    if ! command -v docker &>/dev/null; then
      echo "Error: docker not found. Install Docker Desktop first." >&2
      exit 1
    fi
    if ! docker info &>/dev/null 2>&1; then
      echo "Error: Docker daemon not running. Start Docker Desktop first." >&2
      exit 1
    fi

    if [ -d "$GATEWAY_DIR/.git" ]; then
      echo "Updating airis-mcp-gateway..."
      git -C "$GATEWAY_DIR" pull --ff-only 2>/dev/null || true
    else
      echo "Cloning airis-mcp-gateway..."
      mkdir -p "$(dirname "$GATEWAY_DIR")"
      git clone https://github.com/agiletec-inc/airis-mcp-gateway.git "$GATEWAY_DIR"
    fi

    cp "${gatewayMcpConfig}" "$GATEWAY_DIR/mcp-config.json"
    echo "Copied Nix-managed mcp-config.json"

    echo "Building & starting airis-mcp-gateway (first run may take a few minutes)..."
    cd "$GATEWAY_DIR"
    docker compose up -d --build

    if command -v claude &>/dev/null; then
      claude mcp add --scope user --transport sse airis-mcp-gateway http://localhost:9400/sse 2>/dev/null || true
      echo "Registered gateway with Claude Code (SSE on localhost:9400)"
    fi

    echo ""
    echo "Done!  Health check: curl http://localhost:9400/health"
    echo "To switch back to direct MCP mode, run:  darwin-rebuild switch --flake .#laptop --impure"
  '';

  # Helper: install/upgrade SuperClaude framework
  superclaudeSetupScript = pkgs.writeShellScriptBin "superclaude-setup" ''
    set -euo pipefail
    if ! command -v pipx &>/dev/null; then
      echo "Error: pipx not found" >&2; exit 1
    fi

    echo "Installing/upgrading SuperClaude..."
    pipx install superclaude 2>/dev/null || pipx upgrade superclaude 2>/dev/null || true

    echo "Installing SuperClaude slash commands..."
    superclaude install

    echo ""
    echo "Done!  Restart Claude Code to use /sc:* commands."
    echo "Verify: superclaude install --list"
    echo "Doctor: superclaude doctor"
  '';

in
lib.mkIf pkgs.stdenv.isDarwin {
  home.activation.setupClaudeMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupMcpScript}
  '';

  home.packages = [
    airisSetupScript
    superclaudeSetupScript
  ];
}
