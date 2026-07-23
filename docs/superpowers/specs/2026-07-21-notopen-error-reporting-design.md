# Design: Improve `<NOTOPEN>` error reporting (issue #462)

## Revision (2026-07-21): use `$system.Process.OSError()` instead of active probes

After the initial implementation (Tasks 1-7, all committed), empirical testing in the
container changed the design. `$system.Process.OSError()` returns the actual OS-level
error behind a failed `$zf(-100)` launch, which is more accurate and self-maintaining
than a static list of causes or active probes.

Confirmed by reproduction in the Linux container:

| Scenario | `<NOTOPEN>`? | `OSError()` |
|---|---|---|
| git executable not found (not on PATH / bad absolute path) | Yes | `<2> No such file or directory` (ENOENT) |
| git exists but is not executable | Yes | `<13> Permission denied` (EACCES) |
| git launches but the repo dir is inaccessible | **No** | git returns code 128 with a clear stderr `fatal: cannot change to '...'` — already handled by the normal stderr flow |

Key facts established:

- `OSError()` is a *lingering* "last OS error": it does NOT clear after a subsequent
  *successful* command. BUT it *is* correctly refreshed whenever a *new* launch failure
  occurs (seeded errno 13, then a missing-binary launch correctly reported errno 2). So
  it is reliable **when read in the catch block immediately after the failed launch**,
  which is exactly where `GitLaunchError` runs. It must NOT be read unconditionally on a
  success path.
- The "repo directory permissions" cause from the original issue thread does not surface
  as `<NOTOPEN>` on Linux — git launches and returns code 128 with a descriptive stderr
  message. The `<NOTOPEN>` path is specifically about launching the git process itself.
- `OSError()` is platform-specific; errno 2/13 are POSIX. Windows returns different
  codes, so the design maps the known POSIX codes to specific hints and falls back to
  showing the raw `OSError()` text (which is human-readable on all platforms) for any
  other code.

### Revised architecture

1. **Failure-time translation** (`GitLaunchError`) — read `$system.Process.OSError()` in
   the catch and build a message combining the actual OS error with a targeted hint:
   - errno 2 → git not found; set an absolute path in Settings / add git to PATH.
   - errno 13 → git could not be executed; check the executable's permissions and (on
     Windows) the "Replace a process level token" privilege.
   - any other → show the raw `OSError()` text plus a generic troubleshooting pointer.
   Still no docs link in the runtime message.
2. **Active diagnostics REMOVED.** `DiagnoseGitLaunch` and `DirectoryWritable`, and their
   call sites in `Configure` and `csp/gitprojectsettings.csp`, are removed. `OSError()`
   already pinpoints the launch failure, so the probes add complexity without value.
3. **Troubleshooting docs** — unchanged; the README section stays (with the InterSystems
   `$zf(-100)` link).

The sections below describe the ORIGINAL design (Tasks 1-7). Where they conflict with
this revision, this revision governs.

### Follow-up (2026-07-21): the retry's `<NOTOPEN>` translation was Windows-only

Manual testing in the Linux container found that `GitLaunchError`, as written, never
fired on Linux. The retry branch in `RunGitCommandWithInput` is platform-specific:

- **Windows retry:** `$zf(-100,baseArgs,gitCommand,newArgs...)` — a failed launch
  throws `<NOTOPEN>`, so `GitLaunchError` runs as designed.
- **Linux retry:** `$zf(-100,"/SHELL "_baseArgs,gitCommand,newArgs...)` — `/SHELL`
  shells out to launch git, so a launch failure is absorbed into a normal shell exit
  code instead of throwing: **127** (command not found) or **126** (found, not
  executable). `RunGitCommandWithInput` simply returns 127/126 with no exception and no
  actionable message.

Confirmed empirically (missing git path, then a non-executable git path, both run
through the real Linux `/SHELL` retry):

| Configured git path | Windows retry (`$zf` no `/SHELL`) | Linux retry (`/SHELL`) |
|---|---|---|
| missing | throws `<NOTOPEN>`, OSError `<2>` | returns 127, no throw, OSError cleared |
| exists, not executable | throws `<NOTOPEN>`, OSError `<13>` | returns 126, no throw |

git itself never uses exit codes 126/127 for its own errors (confirmed: an unknown git
subcommand exits 1) — those codes are shell-reserved for "command not found" /
"found but not executable" when the shell can't launch the target at all. So detecting
127/126 specifically after the Linux retry is safe and cannot misfire on a real git
failure.

Fix: after the retry's `try/catch` in `RunGitCommandWithInput`, on non-Windows, check
`returnCode` for 127/126 and throw a new `GitLaunchFailedError(returnCode)` that shares
its hint text with `GitLaunchError` (extracted into `GitNotFoundHint`,
`GitNotExecutableHint`, `GitLaunchGenericHint`). This makes the actionable-message
behavior consistent across both platforms.

## Problem

When git cannot be launched via `$zf(-100)`, IRIS raises a raw `<NOTOPEN>` error that
propagates uncaught out of `SourceControl.Git.Utils:RunGitCommandWithInput`, aborting
the whole flow (e.g. the `Configure` / `Clone` setup script) with a stack like:

```
ERROR #5002: ObjectScript error: <NOTOPEN>RunGitCommandWithInput+151^SourceControl.Git.Utils.1
```

The message tells the user nothing about the actual cause or the fix.

Known causes (from the issue thread):

1. The git executable is not on the IRIS operating user's PATH, and no absolute path
   to the git executable was provided through the Configure prompt.
2. Permissions issues where the IRIS operating user does not own / cannot access the
   Git repo root (namespace temp) directory.
3. On Windows, the IRIS operating user lacks the "Replace a process level token"
   privilege.

## Scope

In scope:

- Catch the `<NOTOPEN>` at failure time and re-throw an actionable message.
- On-demand active diagnostics at two explicit checkpoints (end of `Configure`,
  Settings page load) that probe for the specific cause.
- A Troubleshooting section in `README.md`.

Out of scope:

- Logging these launch failures to `SourceControl_Git.Log`. The `$zf(-100)` failure
  occurs before the log record is written, and logging was explicitly excluded.

## Architecture

Three coordinated pieces. No new classes; all runtime changes live in
`SourceControl.Git.Utils`, `SourceControl.Git.API`, and `csp/gitprojectsettings.csp`.

1. **Failure-time translation** (inline, cheap) — wrap the `$zf(-100)` calls in
   `RunGitCommandWithInput` so a `<NOTOPEN>` is caught and re-thrown as a clear,
   static, multi-cause message.
2. **On-demand active diagnostics** (`DiagnoseGitLaunch`) — a heavier probe method run
   only at two explicit checkpoints. It actually tests each known cause and reports
   which failed.
3. **Troubleshooting docs** — a new Troubleshooting section in `README.md`.

## Piece 1 — Failure-time translation (inline)

Location: `RunGitCommandWithInput`, currently
[Utils.cls:2172-2184](../../../cls/SourceControl/Git/Utils.cls#L2172-L2184).

The current `try/catch` catches an error from the first `$zf(-100)` (the `/ENV`
variant) and retries without `/ENV`. That inner retry is itself unguarded — a
`<NOTOPEN>` there propagates raw.

Change: keep the existing `/ENV`-fallback logic, but wrap the whole block so any
`<NOTOPEN>` (from either attempt) is caught and re-thrown as an actionable exception,
built by a new helper:

```objectscript
ClassMethod GitLaunchError(e As %Exception.AbstractException) As %Exception.AbstractException
```

- Builds a static message listing the three known causes. **No docs link / URL in the
  runtime message.**
- Returns an exception carrying that text; `RunGitCommandWithInput` throws it.
- Only `<NOTOPEN>` (`e.Name = "<NOTOPEN>"`) is translated. Any other error re-throws
  unchanged, so unrelated failures are not masked.

Interaction notes:

- Because the failure happens before the log write at
  [Utils.cls:2247](../../../cls/SourceControl/Git/Utils.cls#L2247), these failures still
  will not reach `SourceControl_Git.Log` — consistent with the out-of-scope decision.
- `GitBinExists` calls `RunGitCommand("--version")` inside its own `try/catch`
  ([Utils.cls:108-113](../../../cls/SourceControl/Git/Utils.cls#L108-L113)) and swallows
  the error to return `version = ""`. The new throw does not disrupt that path since it
  is already caught there.

Runtime message shape (no link):

```
<NOTOPEN>: git could not be launched. Common causes:
 1. git is not on the IRIS user's PATH (set an absolute path to the git
    executable in Configure / the Settings page).
 2. The IRIS user lacks permission on the repository directory.
 3. Windows: the IRIS user lacks the "Replace a process level token" privilege.
```

## Piece 2 — On-demand active diagnostics

New method:

```objectscript
ClassMethod DiagnoseGitLaunch(Output userMessage As %String) As %Boolean
```

Behavior:

- Attempts a real git invocation (`git --version` through the same `$zf(-100)` path).
- Returns `1` (healthy) with an empty `userMessage` on success.
- On `<NOTOPEN>`, runs the active probes and returns `0` with a `userMessage`
  reporting which check(s) failed:
  - **git resolvable** — is `GitBinPath()` the default `"git"` (PATH-dependent) or an
    absolute path? If absolute, does the file exist
    (`##class(%File).Exists`)? If default, note the PATH dependency.
  - **repo dir permissions** — does `TempFolder()` exist and is it writable by the
    IRIS user (attempt a temp-file write / ownership check)?
  - **Windows token privilege** — on Windows, surface the "Replace a process level
    token" privilege as a likely cause (hard to probe directly, so reported as a
    likely cause rather than a definitive check).

Checkpoints (same probe set at both):

1. **End of `Configure()`** ([API.cls:5-38](../../../cls/SourceControl/Git/API.cls#L5-L38))
   — after settings are saved, run the diagnostic and `write` the message to the
   terminal if unhealthy.
2. **Settings page load**
   ([gitprojectsettings.csp:289-310](../../../csp/gitprojectsettings.csp#L289-L310)) —
   render the diagnostic message near the git-path field when unhealthy.

## Piece 3 — Troubleshooting docs (README.md)

Add a "Troubleshooting" section to `README.md`. It documents the `<NOTOPEN>` error:

- What the error looks like (the `<NOTOPEN>...RunGitCommandWithInput` stack).
- The three known causes and their fixes:
  1. git not on the IRIS user's PATH → set an absolute path to the git executable in
     Configure / the Settings page.
  2. IRIS user lacks ownership / permissions on the repo root directory → fix
     ownership / permissions (cross-reference the existing "Dubious Ownership" section).
  3. Windows: grant the IRIS user the "Replace a process level token" privilege
     (cross-reference the existing "IRIS Privileges" section).
- Include the InterSystems `$zf(-100)` error-handling link **in the docs only** (not in
  the runtime message):
  https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzf-100#RCOS_fzf-100_error_handling

## Testing

- Unit-level: verify `GitLaunchError` translates a `<NOTOPEN>` exception into a
  message containing all three causes, and passes non-`<NOTOPEN>` errors through
  unchanged.
- `DiagnoseGitLaunch`: verify it returns healthy when git launches, and returns an
  unhealthy message identifying the git-path probe result when the configured path is
  invalid (e.g. point `%gitBinPath` at a non-existent absolute path).
- Manual: confirm the message renders on the Settings page and prints at the end of
  `Configure` when git is misconfigured.
