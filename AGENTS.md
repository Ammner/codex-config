# AGENTS.md - Cross-Platform Codex and Hermes Rules

## Platform Profiles

Use environment variables first, then infer platform defaults.

Known defaults:

- Windows:
  - `CODEX_HOME=D:\Codex\.codex` or `%USERPROFILE%\.codex`
  - `HERMES_WORK_ROOT=D:\Hermes`
  - `HERMES_HOME=D:\Hermes\.hermes`
- macOS:
  - `CODEX_HOME=$HOME/.codex`
  - `HERMES_WORK_ROOT=$HOME/Hermes`
  - `HERMES_HOME=$HOME/Hermes/.hermes`
- Cloud/Linux:
  - `CODEX_HOME=$HOME/.codex`
  - `HERMES_WORK_ROOT=/workspace/hermes`
  - `HERMES_HOME=/workspace/hermes/.hermes`

Do not assume Windows paths on macOS or cloud. Do not assume macOS paths on Windows.

## Hermes Library

When a request mentions Hermes, OpenClaw, Smith routing, migrated skills, MCP, agent tooling, social media, Xiaohongshu, Amazon, creative workflows, research workflows, or GitHub workflows:

1. Resolve `HERMES_HOME`.
2. Search for matching skills with `rg --files "$HERMES_HOME/skills"` on shell platforms that support it.
3. On Windows PowerShell, use `rg --files "$env:HERMES_HOME\skills"`.
4. Read the closest matching `SKILL.md` before acting.

Common entry points:

- Social media and Xiaohongshu: `social-media/`
- Amazon and product research: `amazon/`
- Creative production and image/video workflows: `creative/`
- Research and web search workflows: `research/`
- GitHub workflows: `github/`
- MCP and agent tooling: `mcp/`, `autonomous-ai-agents/`, `software-development/`
- OpenClaw imports: `openclaw-imports/`

## Hermes CLI Helpers

Prefer these helpers when relevant:

Windows:

```powershell
python "$env:HERMES_HOME\scripts\smith_router.py" --task "..." --json
python "$env:HERMES_HOME\scripts\search_router.py" --classify "..." --json
python "$env:HERMES_HOME\scripts\verify_router.py" --task-type code_change --json
```

macOS/Linux:

```bash
python "$HERMES_HOME/scripts/smith_router.py" --task "..." --json
python "$HERMES_HOME/scripts/search_router.py" --classify "..." --json
python "$HERMES_HOME/scripts/verify_router.py" --task-type code_change --json
```

## Codex Config Sync

The sync repository is expected at:

- Windows: `D:\Hermes\codex-config`
- macOS: `$HOME/Hermes/codex-config`
- Cloud/Linux: `/workspace/codex-config` or repo-provided path

Synchronize templates and rules through Git. Do not synchronize auth tokens, session history, sqlite state, logs, or generated Desktop runtime paths.

## Agent Role Defaults

Use `rules/agent-roles.md` in the sync repository as the durable source of truth for Hermes, Codex, and Claude Code role boundaries.

- Hermes is the coordinating brain: memory, durable context, task state, routing decisions, and long-term storage.
- Codex is the default executor: research, browser work, file work, messages, Xiaohongshu and social publishing workflows, batch work, broad orchestration, and general implementation tasks.
- Claude Code is the deep coding specialist alongside Codex: complex implementation, code planning, code review, debugging, refactoring, testing, and long interactive coding loops.

Command prefix intent:

- `hermes-*`: memory, task ledger, state synchronization, durable context, and routing records.
- `codex-*`: default execution, broad tooling, research, browser automation, publishing workflows, and batch orchestration.
- `cc-*`: Claude Code for deep code work, especially plan, review, loop, debug, fix, refactor, and test workflows.

Do not route `cc-*` or explicit Claude Code requests through Smith/OpenClaw model fallback unless the user asks for remote execution. Do not frame Hermes as the default executor; frame it as the coordinator and memory layer.

## MCP

No-key MCP servers may be enabled by templates. API-key servers should remain disabled or use environment variables. Never commit API keys.

Codex Desktop may add local MCP entries such as `node_repl`; keep those local unless the install script explicitly supports the target platform.

## Memory

Graphiti memory files may exist but remain disabled until dependencies and keys are available:

- Provider config: `$HERMES_HOME/config.yaml`
- FalkorDB example env: `$HERMES_WORK_ROOT/.graphiti/.env.example`
- MCP script: `$HERMES_HOME/scripts/graphiti_mcp_server.py`
