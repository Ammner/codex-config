# Agent Role Defaults

This file is the durable cross-platform source of truth for Hermes, Codex, and Claude Code role boundaries.

## Default Architecture

Hermes is the coordinating brain. Use it for memory, durable context, task state, routing decisions, and long-term storage.

Codex is the default executor. Use it for research, browser work, file work, messages, Xiaohongshu and social publishing workflows, batch work, broad orchestration, and general implementation tasks.

Claude Code is the deep coding specialist used alongside Codex. Use it for complex implementation, code planning, code review, debugging, refactoring, testing, and long interactive coding loops.

## Command Prefix Intent

- `hermes-*`: memory, task ledger, state synchronization, durable context, and routing records.
- `codex-*`: default execution, broad tooling, research, browser automation, publishing workflows, and batch orchestration.
- `cc-*`: Claude Code for deep code work, especially plan, review, loop, debug, fix, refactor, and test workflows.

## Routing Rules

1. Prefer Codex for executable work unless the task is clearly a deep code task or the user explicitly requests Claude Code.
2. Prefer Claude Code for codebase-local depth: implementation plans, reviews, debugging, refactors, tests, long coding sessions, and code-agent loops.
3. Prefer Hermes for persistence: record goals, decisions, final conclusions, artifact paths, task state, and handoff notes.
4. Do not frame Hermes as the default executor. Frame Hermes as the coordinator and memory layer.
5. Do not route `cc-*` or explicit Claude Code requests through Smith/OpenClaw model fallback unless the user asks for remote execution.
6. Use Hermes/OpenClaw or Smith dispatch when the user explicitly asks to dispatch, notify, store, schedule, or coordinate through Hermes.

## Practical Workflow

1. Hermes records the goal, background, constraints, and prior decisions.
2. Codex performs the default execution work.
3. Claude Code handles deep code planning, implementation, review, debugging, refactoring, testing, and long interactive loops.
4. Codex can cross-check Claude Code output, run broader validation, research references, or perform browser and publishing workflows.
5. Hermes stores the final conclusion, artifact paths, task status, and next-step memory.
