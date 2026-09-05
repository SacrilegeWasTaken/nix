# Generates Codex "skills" from the SuperClaude command set — the same 30
# /sc:* prompts `superclaude install` drops into ~/.claude/commands/sc/ for
# Claude Code.
#
# Codex has no file-based slash commands; its equivalent is a *skill*: a
# directory under a skill root (default ~/.codex/skills) containing a SKILL.md
# whose YAML frontmatter declares `name` and a required `description`, and whose
# body holds the instructions the model follows when the skill is selected.
#
# The upstream files are not uniform: most open with a `---` YAML frontmatter,
# agent.md opens with bare `key: value` lines (no leading `---`), and
# business-panel.md has no frontmatter at all (a heading plus a fenced yaml
# block). Some `name` fields are already prefixed (`sc:agent`). Each command is
# therefore normalized to one skill named sc-<command>; Claude-specific
# frontmatter fields (personas, mcp-servers, category, ...) are dropped.
{ fetchFromGitHub, runCommand, python3 }:

let
  # Pinned deliberately; bump rev + hash together to pick up upstream edits.
  rev = "1b81e51db955126ec8983769b96dec575d730c05";

  src = fetchFromGitHub {
    owner = "SuperClaude-Org";
    repo = "SuperClaude_Framework";
    inherit rev;
    hash = "sha256-OrtiVfaogkR0iixW34ZcULZWiCnYMQqk5pSxFbvgvpU=";
  };

  python = python3.withPackages (ps: [ ps.pyyaml ]);
in
runCommand "supercodex-skills" { nativeBuildInputs = [ python ]; } ''
  ${python}/bin/python3 - "$out" "${src}/plugins/superclaude/commands" <<'PY'
  import pathlib
  import re
  import sys

  import yaml

  out = pathlib.Path(sys.argv[1])
  commands_dir = pathlib.Path(sys.argv[2])

  def split_frontmatter(text):
      lines = text.splitlines()
      if not lines:
          return "", text
      if lines[0].strip() == "---":
          for i in range(1, len(lines)):
              if lines[i].strip() == "---":
                  return "\n".join(lines[1:i]), "\n".join(lines[i + 1:])
          return "", text
      # Legacy form: bare `key: value` frontmatter closed by a lone `---`.
      first = lines[0].lstrip()
      if ":" in first and not first.startswith("#"):
          for i in range(len(lines)):
              if lines[i].strip() == "---":
                  return "\n".join(lines[:i]), "\n".join(lines[i + 1:])
      return "", text

  def clean_name(raw):
      raw = raw.strip()
      raw = re.sub(r"^(/)?sc[:/\s]+", "", raw, flags=re.IGNORECASE)
      raw = re.sub(r"[:/]+", "-", raw)
      raw = re.sub(r"[^a-zA-Z0-9_.-]+", "-", raw).strip("-")
      return raw or "command"

  def first_heading(body):
      for line in body.splitlines():
          stripped = line.strip()
          if stripped.startswith("#"):
              stripped = stripped.lstrip("#").strip()
              match = re.match(r"^/?sc:\S+\s*-\s*(.+)$", stripped, flags=re.IGNORECASE)
              return match.group(1) if match else stripped
      return ""

  count = 0
  for md in sorted(commands_dir.glob("*.md")):
      text = md.read_text()
      frontmatter, body = split_frontmatter(text)

      meta = {}
      if frontmatter:
          try:
              parsed = yaml.safe_load(frontmatter)
              if isinstance(parsed, dict):
                  meta = parsed
          except yaml.YAMLError:
              pass

      name = clean_name(str(meta.get("name") or md.stem))
      description = str(meta.get("description") or meta.get("purpose") or "").strip()
      if not description:
          description = first_heading(body) or name

      skill_dir = out / f"sc-{name}"
      skill_dir.mkdir(parents=True, exist_ok=True)
      header = yaml.safe_dump(
          {"name": f"sc-{name}", "description": description},
          sort_keys=False,
          default_flow_style=False,
      ).strip()
      (skill_dir / "SKILL.md").write_text(f"---\n{header}\n---\n\n{body.strip()}\n")
      count += 1

  print(f"generated {count} SuperCodex skills", file=sys.stderr)
  if count == 0:
      sys.exit("no SuperClaude commands found; aborting")
  PY
''
