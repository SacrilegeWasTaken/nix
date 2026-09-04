# stass/lldb-mcp, a single-file Python script MCP server wrapping the system
# `lldb`. Pinned at a fixed commit since upstream has no tagged releases.
# It spawns `lldb` as a subprocess, so any system LLDB on PATH (Xcode CLT
# supplies /usr/bin/lldb) is sufficient -- no Python-binding version match
# required. Shared between the Claude Code and DeepSeek Harness MCP configs.
{ fetchurl, python3, writeShellScriptBin }:

let
  rev = "a610f2d0d3835739c41762352442ba2a13958b38";
  script = fetchurl {
    url = "https://raw.githubusercontent.com/stass/lldb-mcp/${rev}/lldb_mcp.py";
    hash = "sha256-K2ptzfEUga+vPRmOScnExob+DeabVXVTBBnFy7ASCUY=";
  };
  python = python3.withPackages (ps: [ ps.mcp ]);
in
writeShellScriptBin "lldb-mcp-server" ''
  exec ${python}/bin/python3 ${script} "$@"
''
