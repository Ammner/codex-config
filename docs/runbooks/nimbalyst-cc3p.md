# Nimbalyst + `cc 3p`

Nimbalyst must be pointed at an executable, so it cannot call the interactive
PowerShell/zsh `cc 3p` function directly. The launchers in this repository
provide the same environment contract without changing normal `claude` or
`claude-official` sessions.

Both launchers read machine-local credentials from:

```text
~/.hermes/secrets/third-party.env
```

Required keys:

```dotenv
THIRD_PARTY_BASE_URL=https://example.invalid/api
THIRD_PARTY_AUTH_TOKEN=replace-locally
```

Never commit the real file or token.

## Windows

```powershell
D:\Hermes\codex-config\scripts\install-nimbalyst-cc3p-windows.ps1
```

Close Nimbalyst before running the installer. It sets the global Claude Code
custom installation path to:

```text
%USERPROFILE%\bin\nimbalyst-cc3p.exe
```

## macOS

```bash
~/Hermes/codex-config/scripts/install-nimbalyst-cc3p-macos.sh
```

Close Nimbalyst before running the installer. It sets the global Claude Code
custom installation path to:

```text
~/.local/bin/nimbalyst-cc3p
```

## Required Nimbalyst settings

1. Enable Claude Code.
2. Clear the Claude Code API Key field. `cc 3p` uses
   `ANTHROPIC_AUTH_TOKEN`, while a value in the API Key field makes Nimbalyst
   inject `ANTHROPIC_API_KEY` and can shadow the 3P token.
3. Set the custom Claude installation path shown above.
4. Start a new session and ask it to reply with only `OK`.

## Chinese UI

As of Nimbalyst 0.68.1, the desktop UI is English-only. A preferred agent
language can make model output and automatic naming Chinese, but it does not
translate menus and settings. Full Chinese UI requires an upstream/local i18n
implementation rather than a configuration switch.
