# Codex Config Sync GitHub Push Runbook

Date: 2026-05-26

Owner: Codex Desktop on Windows

Remote: `https://github.com/Ammner/codex-config.git`

Final verified commit:

```text
d3f018c230d575e6eea17a11add559e43e484a3e
```

## Result

The local repository `D:\Hermes\codex-config` was pushed to the private GitHub repository:

```text
https://github.com/Ammner/codex-config.git
```

Local `main` tracks `origin/main`:

```powershell
git status -sb
git ls-remote origin refs/heads/main
git rev-parse HEAD
```

Expected state:

```text
## main...origin/main
d3f018c230d575e6eea17a11add559e43e484a3e refs/heads/main
d3f018c230d575e6eea17a11add559e43e484a3e
```

## What Was Built

The sync repository stores portable Codex and Hermes configuration, not runtime state:

- `AGENTS.md`
- `codex/config.common.toml`
- `codex/config.windows.toml`
- `codex/config.macos.toml`
- `codex/config.cloud.toml`
- `scripts/install-windows.ps1`
- `scripts/install-macos.sh`
- `scripts/install-cloud.sh`
- `scripts/github-auth-and-test-windows.ps1`
- `.gitignore`
- `.gitattributes`

Do not commit:

- PATs, API keys, passwords, cookies, tokens
- `auth.json`
- sessions, logs, caches
- sqlite state files
- Codex Desktop generated local MCP paths

## Windows Install Flow

Run:

```powershell
D:\Hermes\codex-config\scripts\install-windows.ps1
```

This copies:

```text
D:\Hermes\codex-config\AGENTS.md
-> D:\Codex\.codex\AGENTS.md
```

It also generates:

```text
D:\Codex\.codex\config.sync.generated.toml
```

By default it does not overwrite:

```text
D:\Codex\.codex\config.toml
```

Reason: Codex Desktop owns machine-specific entries such as local `node_repl` paths.

## GitHub Auth Flow

Use the helper:

```powershell
D:\Hermes\codex-config\scripts\github-auth-and-test-windows.ps1
```

The helper:

1. Prompts for GitHub username.
2. Prompts for PAT using hidden input.
3. Stores the credential through Windows Git Credential Manager.
4. Runs a read test with:

```powershell
git ls-remote https://github.com/Ammner/Github-.git HEAD
```

The helper writes status to:

```text
D:\Hermes\codex-config\tmp\github-auth-test.status
```

Passing status:

```text
OK 2026-05-26T16:03:55
```

Security rule: never paste the PAT into Codex chat, docs, shell history, or Git remote URLs.

Recommended PAT scope:

```text
Fine-grained token
Repository: target private repo only
Permission: Contents Read and Write
Expiry: finite, for example 90 days
```

## Push Flow

After auth passes:

```powershell
cd D:\Hermes\codex-config
git remote add origin https://github.com/Ammner/codex-config.git
git push -u origin main
```

Expected success:

```text
branch 'main' set up to track 'origin/main'.
To https://github.com/Ammner/codex-config.git
 * [new branch]      main -> main
```

## Pitfalls

### 1. Old GitHub Credential Can Be Invalid

Symptom:

```text
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/...'
```

Fix:

```powershell
"protocol=https`nhost=github.com`n`n" | git credential reject
```

Then rerun:

```powershell
D:\Hermes\codex-config\scripts\github-auth-and-test-windows.ps1
```

### 2. GCM Login Can Hang in Non-Interactive Shells

Symptoms:

```text
git credential-manager github login
```

or:

```text
git ls-remote https://github.com/Ammner/Github-.git
```

hangs until timeout.

Reason: Git Credential Manager may be waiting on an interactive browser or UI prompt that is not visible to the Codex shell.

Fix: open a visible PowerShell window and run the helper script. The PAT must be entered by the user locally.

### 3. PowerShell Get-Credential Failed on This Machine

Symptom:

```text
Get-Credential: The term 'Get-Credential' is not recognized...
```

or type data errors involving:

```text
System.Security.AccessControl.ObjectSecurity
```

Fix: the helper script uses:

```powershell
Read-Host -AsSecureString
```

instead of `Get-Credential`.

### 4. Git Global socks5 Proxy Broke GCM

Global config on this machine had:

```text
http.proxy=socks5://127.0.0.1:10808
```

Symptom:

```text
fatal: ServicePointManager does not support proxies with the socks5 scheme.
```

Fix only for this repository:

```powershell
git config http.proxy http://127.0.0.1:10808
git config https.proxy http://127.0.0.1:10808
```

Do not change global proxy unless the user asks.

### 5. GitHub Browser Automation Was Not Reliable

The Chrome extension reached GitHub's new repository page but DOM reads and form actions timed out or detached.

Fallback that worked:

1. Use GitHub connector or API only to check repository existence when available.
2. Use Git Credential Manager credential for local Git auth.
3. Push with plain Git.

If repo creation through API fails with:

```text
422 name already exists on this account
```

then check:

```powershell
git ls-remote https://github.com/Ammner/codex-config.git HEAD
```

Exit code `0` with no output means the private repo exists and is empty.

## Mac Onboarding

On macOS:

```bash
git clone https://github.com/Ammner/codex-config.git ~/Hermes/codex-config
~/Hermes/codex-config/scripts/install-macos.sh
```

Use `--force-config` only on a fresh or intentionally replaced Codex config:

```bash
~/Hermes/codex-config/scripts/install-macos.sh --force-config
```

## Verification Checklist

Run on Windows:

```powershell
cd D:\Hermes\codex-config
git status -sb
git remote -v
git ls-remote origin refs/heads/main
git rev-parse HEAD
```

Pass criteria:

- working tree clean
- `origin` is `https://github.com/Ammner/codex-config.git`
- remote `refs/heads/main` equals local `HEAD`

## 007 Handoff

When sending this to 007 for archival, ask 007 to assign the relevant subagent to update:

- shared knowledge index
- daily memory for 2026-05-26
- long-term memory if the Git/GCM/proxy lessons are generally reusable
- any GitHub/Codex/Hermes runbook category

Acceptance criteria for 007:

- The final remote URL is recorded.
- The PAT handling rule is recorded.
- The local-only proxy fix is recorded.
- The PowerShell helper script path is recorded.
- The Mac clone/install commands are recorded.
- Evidence or exact file path of the archived entry is returned.
