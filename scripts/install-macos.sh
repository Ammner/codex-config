#!/usr/bin/env bash
set -euo pipefail

force_config=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force-config)
      force_config=true
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

codex_home="${CODEX_HOME:-$HOME/.codex}"
codex_work_root="${CODEX_WORK_ROOT:-$HOME/Codex}"
hermes_work_root="${HERMES_WORK_ROOT:-$HOME/Hermes}"
hermes_home="${HERMES_HOME:-$hermes_work_root/.hermes}"
graphiti_home="${GRAPHITI_HOME:-$hermes_work_root/.graphiti}"

mkdir -p "$codex_home"
mkdir -p "$hermes_work_root/tmp"
mkdir -p "$hermes_work_root/logs/playwright"
mkdir -p "$hermes_work_root/browser-profiles/chrome-devtools"
mkdir -p "$hermes_work_root/browser-profiles/playwright"

agents_target="$codex_home/AGENTS.md"
if [[ -f "$agents_target" ]]; then
  cp "$agents_target" "$agents_target.bak"
fi
cp "$repo_root/AGENTS.md" "$agents_target"

overlay="$(cat "$repo_root/codex/config.macos.toml")"
overlay="${overlay//\{\{CODEX_WORK_ROOT\}\}/$codex_work_root}"
overlay="${overlay//\{\{HERMES_WORK_ROOT\}\}/$hermes_work_root}"

generated_path="$codex_home/config.sync.generated.toml"
{
  cat "$repo_root/codex/config.common.toml"
  printf "\n"
  printf "%s\n" "$overlay"
} > "$generated_path"

config_path="$codex_home/config.toml"
if [[ ! -f "$config_path" || "$force_config" == "true" ]]; then
  if [[ -f "$config_path" ]]; then
    cp "$config_path" "$config_path.bak-$(date +%Y%m%d-%H%M%S)"
  fi
  cp "$generated_path" "$config_path"
  echo "Wrote active Codex config: $config_path"
else
  echo "Left active Codex config unchanged: $config_path"
  echo "Generated synced template: $generated_path"
fi

profile_file="$HOME/.zshrc"
touch "$profile_file"

add_export() {
  local key="$1"
  local value="$2"
  if grep -q "^export $key=" "$profile_file"; then
    return
  fi
  printf 'export %s="%s"\n' "$key" "$value" >> "$profile_file"
}

add_export "CODEX_HOME" "$codex_home"
add_export "HERMES_WORK_ROOT" "$hermes_work_root"
add_export "HERMES_HOME" "$hermes_home"
add_export "GRAPHITI_HOME" "$graphiti_home"
add_export "NPM_CONFIG_CACHE" "$hermes_work_root/npm-cache"
add_export "PIP_CACHE_DIR" "$hermes_work_root/pip-cache"
add_export "UV_CACHE_DIR" "$hermes_work_root/uv-cache"

echo "Copied AGENTS.md to: $agents_target"
echo "Updated shell env in: $profile_file"
