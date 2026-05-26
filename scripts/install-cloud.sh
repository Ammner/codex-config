#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

codex_home="${CODEX_HOME:-$HOME/.codex}"
mkdir -p "$codex_home"

cp "$repo_root/AGENTS.md" "$codex_home/AGENTS.md"
{
  cat "$repo_root/codex/config.common.toml"
  printf "\n"
  cat "$repo_root/codex/config.cloud.toml"
} > "$codex_home/config.sync.generated.toml"

if [[ ! -f "$codex_home/config.toml" ]]; then
  cp "$codex_home/config.sync.generated.toml" "$codex_home/config.toml"
fi

echo "Installed cloud Codex config into: $codex_home"
