#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
install_dir="${NIMBALYST_CC3P_INSTALL_DIR:-$HOME/.local/bin}"
target="$install_dir/nimbalyst-cc3p"
secret_file="${CC3P_SECRET_FILE:-$HOME/.hermes/secrets/third-party.env}"

if [[ ! -f "$secret_file" ]]; then
  echo "Missing CC 3P secret file: $secret_file" >&2
  exit 1
fi
if ! grep -Eq '^[[:space:]]*THIRD_PARTY_AUTH_TOKEN=' "$secret_file"; then
  echo "THIRD_PARTY_AUTH_TOKEN is missing from $secret_file" >&2
  exit 1
fi

mkdir -p "$install_dir"
cp "$repo_root/claude/nimbalyst-cc3p" "$target"
chmod 700 "$target"

echo "Installed Nimbalyst CC 3P launcher: $target"

settings_path="$HOME/Library/Application Support/@nimbalyst/electron/ai-settings.json"
if [[ -f "$settings_path" ]]; then
  if pgrep -x Nimbalyst >/dev/null 2>&1; then
    echo "Nimbalyst is running. Close it, then rerun this installer to update its configuration safely." >&2
    exit 1
  fi
  cp "$settings_path" "$settings_path.bak-$(date +%Y%m%d-%H%M%S)"
  python3 - "$settings_path" "$target" <<'PY'
import json
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
target = sys.argv[2]
settings = json.loads(path.read_text(encoding="utf-8"))
settings["customClaudeCodePath"] = target
settings.get("apiKeys", {}).pop("claude-code", None)
for container_name in ("environmentVariables", "envVars"):
    container = settings.get(container_name, {})
    for name in ("ANTHROPIC_BASE_URL", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY"):
        container.pop(name, None)
temporary = path.with_suffix(path.suffix + ".new")
temporary.write_text(json.dumps(settings, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
os.replace(temporary, path)
PY
  echo "Configured Nimbalyst custom Claude path: $target"
  echo "Cleared the conflicting Claude API Key and stale copied 3P variables."
else
  echo "Nimbalyst settings were not found at: $settings_path"
  echo "After installing Nimbalyst, set Custom Claude Installation to: $target"
fi
