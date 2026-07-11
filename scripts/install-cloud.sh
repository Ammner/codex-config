#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

codex_home="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$codex_home"

cp "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"

claude_home="$HOME/.claude"
claude_rules_dir="$claude_home/rules"
claude_md="$claude_home/CLAUDE.md"
mkdir -p "$claude_rules_dir"
cp "$repo_root/rules/agent-roles.md" "$claude_rules_dir/agent-roles.md"
claude_role_section="$(cat <<'EOF'
<!-- codex-config:agent-roles:start -->
## Hermes, Codex, and Claude Code Roles

Load and follow `~/.claude/rules/agent-roles.md` for the durable role split:

- Hermes is the coordinating brain for memory, durable context, task state, routing decisions, and long-term storage.
- Codex is the default executor for research, browser work, file work, messages, Xiaohongshu and social publishing workflows, batch work, broad orchestration, and general implementation tasks.
- Claude Code is the deep coding specialist for complex implementation, planning, review, debugging, refactoring, testing, and long interactive coding loops.

Do not route `cc-*` or explicit Claude Code requests through Smith/OpenClaw model fallback unless the user asks for remote execution.
<!-- codex-config:agent-roles:end -->
EOF
)"

if [[ -f "$claude_md" ]] && grep -q "<!-- codex-config:agent-roles:start -->" "$claude_md"; then
  python3 - "$claude_md" "$claude_role_section" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
section = sys.argv[2]
text = path.read_text(encoding="utf-8")
text = re.sub(r"(?s)<!-- codex-config:agent-roles:start -->.*?<!-- codex-config:agent-roles:end -->", section, text)
path.write_text(text, encoding="utf-8")
PY
elif [[ -f "$claude_md" ]]; then
  {
    printf "\n"
    printf "%s\n" "$claude_role_section"
  } >> "$claude_md"
else
  {
    printf "# Claude Code Global Instructions\n\n"
    printf "%s\n" "$claude_role_section"
  } > "$claude_md"
fi

{
  cat "$repo_root/codex/config.common.toml"
  printf "\n"
  cat "$repo_root/codex/config.cloud.toml"
} > "$codex_home/config.sync.generated.toml"

if [[ ! -f "$codex_home/config.toml" ]]; then
  cp "$codex_home/config.sync.generated.toml" "$codex_home/config.toml"
fi

echo "Installed cloud Codex config into: $codex_home"
echo "Installed Claude Code role rules into: $claude_rules_dir"
