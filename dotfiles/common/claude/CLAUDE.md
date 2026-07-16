# Git
- One logical change per commit. If a task touches unrelated concerns (e.g. a fix plus a
  config tweak), split them into separate commits.
- Commit messages are self-explanatory: imperative summary line matching project style-guide;
  add a body only when the "why" is not obvious from the diff.
- NEVER add a Co-Authored-By trailer or any other AI attribution to commits or PRs.
- NEVER merge branches unless explicitly asked to merge.

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
- Automatic notifications are handled by hooks (home-manager, claude-code.nix): the Stop
  hook fires on turn completion with the first line of your last reply; the Notification
  hook fires when you wait for permission or input. NEVER duplicate them manually.
- Send a manual notification only for events the hooks cannot cover — a milestone inside a
  long-running task, or a failure the user must see immediately:
  `osascript -e 'display notification "<message>" with title "Claude Code" sound name "Glass"'`
- Notification text: under 100 characters, plain text, no double quotes.
