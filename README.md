# Codex Config Sync

This repository syncs portable Codex and Hermes rules across Windows, macOS, and cloud environments.

It intentionally stores templates and install scripts, not machine-owned runtime files.

## What Syncs

- `AGENTS.md`
- Codex config templates under `codex/`
- Hermes bridge notes under `hermes/`
- install scripts under `scripts/`
- environment examples under `env/`

## What Does Not Sync

- `auth.json`
- API keys and `.env` files
- session history
- logs and caches
- Codex Desktop generated paths such as `node_repl.exe`
- sqlite state files

## Profiles

| Profile | CODEX_HOME | HERMES_WORK_ROOT | HERMES_HOME |
| --- | --- | --- | --- |
| Windows | `D:\Codex\.codex` or `%USERPROFILE%\.codex` | `D:\Hermes` | `D:\Hermes\.hermes` |
| macOS | `$HOME/.codex` | `$HOME/Hermes` | `$HOME/Hermes/.hermes` |
| Cloud | `$HOME/.codex` or workspace-provided | `/workspace/hermes` | `/workspace/hermes/.hermes` |

## Windows Install

Run from PowerShell:

```powershell
D:\Hermes\codex-config\scripts\install-windows.ps1
```

This copies `AGENTS.md`, sets user environment variables, and writes:

```text
<CODEX_HOME>\config.sync.generated.toml
```

It does not overwrite the active Codex Desktop config unless you pass:

```powershell
D:\Hermes\codex-config\scripts\install-windows.ps1 -ForceConfig
```

## macOS Install

Run:

```bash
~/Hermes/codex-config/scripts/install-macos.sh
```

Use `--force-config` only on a fresh or intentionally replaced Codex config:

```bash
~/Hermes/codex-config/scripts/install-macos.sh --force-config
```

## Git Setup

After reviewing files:

```bash
git remote add origin <your-private-repo-url>
git push -u origin main
```

Keep this repository private if you add personal workflow rules.

## Runbooks

- [Codex Config Sync GitHub Push Runbook](docs/runbooks/codex-config-sync-github-push.md)
