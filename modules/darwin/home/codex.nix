# Declarative OpenAI Codex setup: the shared MCP server set plus the SuperClaude
# command set ported to Codex "skills" (the SuperCodex-style framework).
#
# MCP -- mirrors the Claude Code + dsh server set (context7, sequential-thinking,
# playwright, serena, tavily, lldb) so every harness in the fleet exposes the
# same tools. Written into ~/.codex/config.toml under [mcp_servers.*] on every
# rebuild, preserving unrelated settings (projects, model, ...).
#
# Instructions -- share Claude Code's global instructions as ~/.codex/AGENTS.md
# and discover repository CLAUDE.md files when no AGENTS file takes precedence.
#
# Codex does NOT inherit the full ambient environment for stdio MCP servers:
# it copies only a fixed allowlist (HOME, PATH, ...) plus vars named in
# `env_vars`. Tavily therefore lists TAVILY_API_KEY explicitly; the key itself
# is decrypted by sops-nix to /run/secrets/tavily-api-key and exported by fish,
# so no secret is baked into this repo or into config.toml.
#
# Skills -- SuperClaude's 30 /sc:* prompts (the same files `superclaude install`
# writes for Claude Code) become ~/.codex/skills/sc-*/SKILL.md via
# pkgs/supercodex-skills.nix. Codex has no file-based slash commands; a skill is
# its equivalent, selected by name or by matching the task against its
# description.
{ config, pkgs, lib, ... }:

let
  lldbMcpServer = pkgs.callPackage ../../../pkgs/lldb-mcp.nix { };
  supercodexSkills = pkgs.callPackage ../../../pkgs/supercodex-skills.nix { };

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
        fallback_filenames = data.setdefault("project_doc_fallback_filenames", [])
        if "CLAUDE.md" not in fallback_filenames:
            fallback_filenames.append("CLAUDE.md")

        os.makedirs(codex_home, exist_ok=True)
        with open(config_path, "w") as f:
            f.write(dumps(data))
        os.chmod(config_path, 0o600)
    except tomllib.TOMLDecodeError as e:
        print(f"Warning: codex MCP setup skipped (config.toml unparsable): {e}", file=sys.stderr)
    except Exception as e:
        print(f"Warning: codex MCP setup skipped: {e}", file=sys.stderr)
  '';

  # Sync the generated skills into ~/.codex/skills, owning only the sc-* prefix
  # so the user's own skills coexist. Idempotent: refreshes every sc-* dir and
  # removes sc-* skills no longer generated upstream.
  setupCodexSkillsScript = pkgs.writeShellScript "setup-codex-skills" ''
    set -euo pipefail
    SRC="${supercodexSkills}"
    DST="$HOME/.codex/skills"
    mkdir -p "$DST"
    # Skills ship read-only from the store; cp -R preserves that, so chmod -R
    # u+w both before (to clear a previous copy) and after (so the next run can).
    for d in "$SRC"/sc-*; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      chmod -R u+w "$DST/$name" 2>/dev/null || true
      rm -rf "$DST/$name"
      cp -R "$d" "$DST/$name"
      chmod -R u+w "$DST/$name"
    done
    for d in "$DST"/sc-*; do
      [ -d "$d" ] || continue
      name="$(basename "$d")"
      if [ ! -d "$SRC/$name" ]; then
        chmod -R u+w "$d" 2>/dev/null || true
        rm -rf "$d"
      fi
    done
  '';
in
lib.mkIf pkgs.stdenv.isDarwin {
  home.file.".codex/AGENTS.md".source = config.home.file.".claude/CLAUDE.md".source;

  home.activation.setupCodexMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupCodexMcpScript}
  '';

  home.activation.setupCodexSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${setupCodexSkillsScript}
  '';
}
