---
name: iris-dev
description: Develop and test Embedded Git for IRIS. Use when you need to connect to the IRIS container (SSH, ObjectScript), interact with the Management Portal or Git Web UI (Playwright CLI), or test Embedded Git behavior (initialize repos, create branches, reload modules).
---

# IRIS Development Skill

Skill for developing and testing the Embedded Git extension against an IRIS instance running in a dev container.

## Architecture

Claude Code runs in the **workspace** container. IRIS runs in a separate **iris** container. They share the repository via a volume mount:

| Container | Mount path |
|-----------|-----------|
| workspace | `/workspace` |
| iris | `/home/irisowner/dev/git-source-control/` |

You do **NOT** have sudo permissions on either container.

---

## 1. Connecting to the IRIS Container (SSH)

The IRIS container is accessible via SSH using the hostname `iris`.

### Running ObjectScript Commands

```bash
ssh iris << 'EOF'
iris session iris -UUSER << 'IRIS'
write $zversion, !
halt
IRIS
EOF
```

**Key rules:**
- Always quote heredoc delimiters (`'EOF'` and `'IRIS'`) to prevent shell expansion
- Always end the IRIS session with `halt`
- Use `-U<NAMESPACE>` to select the namespace (e.g., `-U%SYS`, `-UUSER`)

### Running Shell Commands on the IRIS Container

```bash
ssh iris "ls -la /usr/irissys/mgr/"
ssh iris "cd /home/irisowner/dev/git-source-control && git log --oneline -5"
```

### Container Details

- **Hostname:** `iris`
- **Port mapping:** 52774 (host) -> 52773 (container)
- **IRIS instance name:** IRIS
- **Default OS user:** irisowner (no sudo)

---

## 2. Browser Automation (Playwright CLI)

Use the `playwright-cli` command **from the workspace container** to interact with the IRIS Management Portal and Git Web UI via headless Chrome.

### Authentication

Every new browser session requires login:
- **Username:** superuser
- **Password:** SYS

### Login Pattern

```bash
playwright-cli open http://iris:52773/csp/sys/UtilHome.csp
playwright-cli snapshot
# Read the snapshot YAML to find refs for username, password, and login button
playwright-cli fill <username-ref> superuser
playwright-cli fill <password-ref> SYS
playwright-cli click <login-button-ref>
playwright-cli snapshot   # verify title changed to "IRIS - Home"
```

Session state cannot be saved/restored across sessions. You must log in every time.

### Snapshot vs Screenshot

Prefer `snapshot` over `screenshot`. Snapshot returns structured YAML with element refs you can use for interaction. Use `screenshot` only when visual layout matters.

```bash
playwright-cli snapshot
playwright-cli screenshot --filename=.playwright-cli/page.png
```

### Interacting with Pages

Always take a snapshot first to discover element refs, then use the refs:

```bash
playwright-cli fill <ref> value
playwright-cli fill <ref> value --submit
playwright-cli click <ref>
playwright-cli select <ref> value
playwright-cli goto <url>
```

### Always Close When Done

```bash
playwright-cli close
```

### Command Reference

| Command | Purpose |
|---------|---------|
| `open <url>` | Start headless browser, navigate to URL |
| `goto <url>` | Navigate within existing session |
| `snapshot` | Structured YAML with element refs |
| `screenshot --filename=<path>` | Visual screenshot |
| `fill <ref> <text>` | Fill a form field |
| `fill <ref> <text> --submit` | Fill and press Enter |
| `click <ref>` | Click an element |
| `select <ref> <val>` | Select dropdown option |
| `close` | Close the browser session |

### Common Portal URLs

| Page | URL |
|------|-----|
| Home / Dashboard | `http://iris:52773/csp/sys/UtilHome.csp` |
| Git Web UI (USER) | `http://iris:52773/isc/studio/usertemplates/gitsourcecontrol/webuidriver.csp/USER/` |
| Git Pull (USER) | `http://iris:52773/isc/studio/usertemplates/gitsourcecontrol/pull.csp?$NAMESPACE=USER` |
| Class list (USER) | `http://iris:52773/csp/sys/mgr/%25CSP.UI.Portal.ClassList.zen?$NAMESPACE=USER` |
| Production config | `http://iris:52773/csp/user/EnsPortal.ProductionConfig.zen?$NAMESPACE=USER&` |

---

## 3. Embedded Git Development and Testing

### Rebuilding After Code Changes

After editing source files (ObjectScript classes, web UI JavaScript, CSP pages), reload the module in IRIS:

```bash
ssh iris << 'EOF'
iris session iris -UUSER << 'IRIS'
zpm "load /home/irisowner/dev/git-source-control -dev"
halt
IRIS
EOF
```

This runs `npm ci && npm run build` (grunt release) for the web UI, compiles ObjectScript classes, copies CSP/web files to the IRIS installation directory, and re-configures web applications.

**Important:** zpm must be run in the USER namespace (not %SYS). The path is the IRIS container's mount path (`/home/irisowner/dev/git-source-control`), not the workspace path (`/workspace`).

### Setting Up a Test Repository

**Never use the mounted git-source-control repository for testing Embedded Git behavior.** Instead, initialize a fresh repository on the IRIS container:

```bash
ssh iris << 'EOF'
iris session iris -UUSER << 'IRIS'
// Configure Embedded Git settings
set settings = ##class(SourceControl.Git.Settings).%New()
set settings.namespaceTemp = "/usr/irissys/mgr/repo/USER/"
set settings.gitUserName = "Test User"
set settings.gitUserEmail = "test@example.com"
do settings.%Save()

// Initialize the repository
do ##class(SourceControl.Git.Utils).Init()
halt
IRIS
EOF
```

Then create an initial commit and test branches via SSH shell commands:

```bash
ssh iris "cd /usr/irissys/mgr/repo/USER && git config user.name 'Test User' && git config user.email 'test@example.com' && echo '# Test' > README.md && git add . && git commit -m 'Initial commit'"
ssh iris "cd /usr/irissys/mgr/repo/USER && git branch 'feature/test-branch'"
```

### Verifying in the Git Web UI

Open the Git Web UI in a browser session, log in, and check that your test branches appear:

```bash
playwright-cli open http://iris:52773/isc/studio/usertemplates/gitsourcecontrol/webuidriver.csp/USER/
playwright-cli snapshot
# Log in (see Authentication section above)
playwright-cli snapshot   # verify branches appear under "Local Branches"
playwright-cli close
```

### Key Settings Class Properties

The `SourceControl.Git.Settings` class uses these properties:

| Property | Purpose |
|----------|---------|
| `namespaceTemp` | Local git repo root directory |
| `gitBinPath` | Path to git executable (usually auto-detected) |
| `gitUserName` | Git attribution name for current user |
| `gitUserEmail` | Git attribution email for current user |
| `pullEventClass` | Event handler class for git pull |
| `decomposeProductions` | Source-control productions as separate files |

Save settings with `do settings.%Save()` or `do settings.SaveWithSourceControl()` (the latter also exports the config file to the repo).
