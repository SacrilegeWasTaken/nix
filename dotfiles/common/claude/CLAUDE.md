# System Configuration (nix-darwin)
- The system is fully declarative: ~/Projects/Darwin (nix-darwin + home-manager flake).
- Any request to install a package, change a system setting, or tweak dotfiles means
  editing this repo. NEVER mutate the system directly (no brew install, no manual
  edits of files that home-manager owns).
- Before editing, explore the repo with `tree` and `rg`: find where similar things
  already live and follow that pattern. If unsure how to organize a change — ask.
- Validate with `nix build .#darwinConfigurations.laptop.system --impure` before committing.
- When the change is done and validated: commit and push to origin without asking.
  This auto-push rule applies to THIS repo only.
- Files from dotfiles/ are symlinked into place via the nix store; remind the user to run
  `darwin-rebuild switch --flake .#laptop --impure` for changes to take effect.

# Git
- One logical change per commit. If a task touches unrelated concerns (e.g. a fix plus a
  config tweak), split them into separate commits.
- Commit messages are self-explanatory: imperative summary line matching project style-guide;
  add a body only when the "why" is not obvious from the diff.
- NEVER add a Co-Authored-By trailer or any other AI attribution to commits or PRs.
- NEVER merge branches unless explicitly asked to merge.
- NEVER commit or push on your own initiative. The only exception is ~/Projects/Darwin
  (see System Configuration).

# Code Style
- Prefer self-documenting code: clear names and small focused functions instead of inline
  comments that explain what the code does.
- Public APIs (exported functions, types, modules) get doc-comments describing purpose and
  contract. Do not write comments that restate the code.

# Tools
- Search file contents with `rg` (never `grep`).
- Find files with `fd` (never `find`).
- Explore directory or project structure with `tree`.

# Language
- Everything that lands in files or git is English ONLY: code, comments, docs, examples,
  commit messages, configs, error messages, tests.
- If you encounter non-English text in code you are touching, translate it to English as
  part of the change.
- Reply in the chat in Russian, unless explicitly asked to switch languages.

# Notifications (macOS)
- If the user's message ends with `--notify`, you MUST send a macOS notification the moment
  the requested work finishes — script completed, build succeeded or failed, implementation
  done, tests passed, etc.:
  `osascript -e 'display notification "<one-line outcome>" with title "Claude Code"'; afplay /System/Library/Sounds/Glass.aiff`
  (sound via `afplay`, not `sound name` — plain audio playback cuts through Focus/DND while
  notification sounds get muted by it)
- The text states the outcome, not the process ("build OK", "tests: 3 failed", "refactor done"):
  under 100 characters, plain text, no double quotes.
- `--notify` applies to the whole task: if it has several long stages (e.g. build, then tests),
  notify after each stage that takes noticeable time, and always on any failure.
- Without `--notify`, do not send notifications.
