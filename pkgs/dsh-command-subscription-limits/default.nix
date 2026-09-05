# A dsh (DeepSeek Harness) plugin registering the `/subscription-limits` slash
# command, which reports the Claude and Codex subscription usage windows that
# neither the TUI nor the CLI otherwise surfaces: dsh-codex-subscription draws
# its quota only in the web client, and Claude Code's `/usage` is a client-side
# command with no CLI equivalent.
#
# Plain ESM with no dependencies, so the harness loads it straight from the
# store path spliced into ~/.dsh/cordis.patch.yml -- no npm install into a
# profile, nothing to keep in sync with pnpm.
{ runCommand, writeText }:

let
  packageJson = writeText "package.json" (builtins.toJSON {
    name = "dsh-command-subscription-limits";
    version = "0.1.0";
    private = true;
    type = "module";
    main = "lib/index.js";
  });
in
runCommand "dsh-command-subscription-limits" { } ''
  mkdir -p "$out/lib"
  cp ${./index.js} "$out/lib/index.js"
  cp ${packageJson} "$out/package.json"
''
