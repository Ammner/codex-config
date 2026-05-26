# Hermes Bridge Notes

This file documents the portable Hermes bridge used by Codex.

## Path Contract

Use:

- `HERMES_WORK_ROOT` for the root work area.
- `HERMES_HOME` for the Hermes agent home.
- `CODEX_HOME` for Codex local state.

Avoid hardcoded `D:\Hermes`, `/Users/...`, or `/workspace/...` paths inside reusable prompts and skills unless the file is explicitly platform-specific.

## Cloud Behavior

Cloud agents should treat local Desktop paths as unavailable. If a task needs Windows or macOS-only tools, report the missing platform dependency and ask for a local run or remote bridge.

## Safe Sync Boundary

Sync:

- portable skills
- portable scripts
- AGENTS files
- config templates

Do not sync:

- OAuth tokens
- provider API keys
- session transcripts unless explicitly exported for review
- machine cache directories
- generated binaries or app-managed Desktop paths
