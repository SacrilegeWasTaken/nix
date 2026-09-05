# Declarative MCP server configuration for OpenAI Codex.
#
# Mirrors the Claude Code + dsh server set (context7, sequential-thinking,
# playwright, serena, tavily, lldb) so every harness in the fleet exposes the
# same tools. Written into ~/.codex/config.toml under [mcp_servers.*] on every
# rebuild, preserving every other section (projects, model, ...).
#
# Codex does NOT inherit the full ambient environment for stdio MCP servers:
# it copies only a fixed allowlist (HOME, PATH, ...) plus vars named in
# `env_vars`. Tavily therefore lists TAVILY_API_KEY explicitly; the key itself
# is decrypted by sops-nix to /run/secrets/tavily-api-key and exported by fish,
# so no secret is baked into this repo or into config.toml.
{ config, pkgs, lib, ... }:

let
  lldbMcpServer = pkgs.callPackage ../../../pkgs/lldb-mcp.nix { };

  # stdio servers, keyed by the [mcp_servers.<name>] table name. `env_vars`
  # names ambient vars codex should copy into the server's launch environment.
  mcpServers = {
    context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp@latest" ];
    };
    "sequential-thinking" = {
      command = "npx";
      args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
    };
    playwright = {
      command = "npx";
      args = [ "-y" "@playwright/mcp@latest" ];
    };
    serena = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/oraios/serena"
        "serena"
        "start-mcp-server"
      ];
    };
    tavily = {
      command = "npx";
      args = [ "-y" "tavily-mcp@latest" ];
      env_vars = [ "TAVILY_API_KEY" ];
    };
    lldb = {
      command = "${lldbMcpServer}/bin/lldb-mcp-server";
      args = [ ];
    };
  };

  mcpConfigFile = pkgs.writeText "codex-mcp-servers.json" (builtins.toJSON mcpServers);

  python = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);

  setupCodexMcpScript = pkgs.writeScript "setup-codex-mcp" ''
    #!${python}/bin/python3
    import json
    import os
    import sys
    import tomllib
    from tomli_w import dumps

    codex_home = os.path.expanduser("~/.codex")
    config_path = os.path.join(codex_home, "config.toml")

    try:
        with open("${mcpConfigFile}") as f:
            servers = json.load(f)

        data = {}
        try:
            with open(config_path, "rb") as f:
                data = tomllib.load(f)
        except FileNotFoundError:
            pass

        data["mcp_servers"] = servers

        os.makedirs(codex_home, exist_ok=True)
        with open(config_path, "w") as f:
            f.write(dumps(data))
        os.chmod(config_path, 0o600)
    except tomllib.TOMLDecodeError as e:
        print(f"Warning: codex MCP setup skipped (config.toml unparsable): {e}", file=sys.stderr)
    except Exception as e:
        print(f"Warning: codex MCP setup skipped: {e}", file=sys.stderr)
  '';
in
lib.mkIf pkgs.stdenv.isDarwin {
  home.activation.setupCodexMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupCodexMcpScript}
  '';
}
