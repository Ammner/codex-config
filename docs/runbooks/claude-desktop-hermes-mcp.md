# Claude Desktop Hermes MCP disconnect

## Symptom

Claude Desktop's Developer page marks `hermes` as `failed` with `Server disconnected` or `Could not attach to MCP server hermes`.

## Verified cause

Claude Desktop uses MCP protocol `2025-11-25` and closes a stdio server if it does not receive an `initialize` response almost immediately. A direct Windows SSH command cannot establish the remote session in that window; system OpenSSH also returned exit code `255` when spawned by the packaged Desktop app.

## Repair pattern

1. Use a local Python MCP proxy as Claude's configured command, not `ssh.exe` directly.
2. The proxy must immediately respond to `initialize`, echoing the client's requested protocol version.
3. Start Hermes over Git for Windows' `ssh.exe` in the background (`-T`, explicit key and `known_hosts` paths).
4. Buffer client messages until the remote Hermes server finishes cold start, then bridge both streams.
5. Reply to initial `tools/list`, `prompts/list`, and `resources/list` immediately. Keep a sanitized cached Hermes tool catalog in the local proxy; once Hermes is ready, forward actual tool calls.

## Local runtime artifacts

These are intentionally not committed because they contain user-specific paths and are Desktop runtime configuration:

- `%USERPROFILE%\.hermes\mcp_ssh_hermes.py`
- `%APPDATA%\Claude\claude_desktop_config.json`
- `%APPDATA%\Claude\logs\hermes-ssh-wrapper.log`

The config should invoke the local Python proxy. Do not configure Claude Desktop to call `ssh.exe` directly or use the `HermesServer` SSH alias: that alias has an unrelated `RemoteForward 4444` rule.

## Verification

After a full Claude Desktop restart, confirm its MCP log records, in order:

1. an `initialize` response;
2. immediate results for the three discovery methods;
3. no `Server transport closed unexpectedly` entry;
4. local proxy log `Hermes initialized; enabling transparent bridge`.

If the proxy does not reach the remote process, inspect the local proxy log first. A packaged Claude Desktop process may not run the system OpenSSH client reliably; use Git for Windows' `ssh.exe` through the local proxy.
