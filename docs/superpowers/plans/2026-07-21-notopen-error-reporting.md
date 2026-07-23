# Improve `<NOTOPEN>` Error Reporting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the raw, uncaught `<NOTOPEN>` error from failed git launches with an actionable message, add on-demand active diagnostics at Configure/Settings, and document the error in the README.

**Architecture:** All runtime logic lives in `SourceControl.Git.Utils`. `RunGitCommandWithInput` catches `<NOTOPEN>` from the `$zf(-100)` call and re-throws a static multi-cause message via a new `GitLaunchError` helper. A separate `DiagnoseGitLaunch` method actively probes for the specific cause and is invoked at the end of `SourceControl.Git.API:Configure` and on load of `csp/gitprojectsettings.csp`. Docs live in `README.md`.

**Tech Stack:** InterSystems ObjectScript, IRIS `%UnitTest.TestCase`, CSP.

## Global Constraints

- Language: InterSystems ObjectScript. Follow existing conventions in `SourceControl.Git.Utils` (lowercase `set`/`quit`/`do`, `##class(...)`, `$$$` macros).
- Only `<NOTOPEN>` errors are translated. Any other exception must re-throw unchanged so unrelated failures are not masked.
- The runtime failure-time message must NOT contain a docs link / URL.
- The three known causes, referenced verbatim where a message lists them:
  1. git is not on the IRIS user's PATH (set an absolute path to the git executable in Configure / the Settings page).
  2. The IRIS user lacks permission on the repository directory.
  3. Windows: the IRIS user lacks the "Replace a process level token" privilege.
- The InterSystems `$zf(-100)` error-handling link appears in `README.md` ONLY:
  `https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzf-100#RCOS_fzf-100_error_handling`
- Test classes extend `UnitTest.SourceControl.Git.AbstractTest` and live under `test/UnitTest/SourceControl/Git/`.
- Do not commit to `main`. Work is on branch `diagnose-notopen-errors`.

## File Structure

- Modify: `cls/SourceControl/Git/Utils.cls`
  - Add `GitLaunchError` classmethod (builds the actionable exception).
  - Add `DiagnoseGitLaunch` classmethod (active probes; returns healthy boolean + message).
  - Wrap the `$zf(-100)` block in `RunGitCommandWithInput` to translate `<NOTOPEN>`.
- Modify: `cls/SourceControl/Git/API.cls`
  - Call `DiagnoseGitLaunch` at the end of `Configure` and print the message if unhealthy.
- Modify: `csp/gitprojectsettings.csp`
  - Call `DiagnoseGitLaunch` on page load and render the message near the git-path field if unhealthy.
- Modify: `README.md`
  - Add a Troubleshooting section for `<NOTOPEN>`.
- Create: `test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls`
  - Unit tests for `GitLaunchError` and `DiagnoseGitLaunch`.

---

### Task 1: `GitLaunchError` helper — translate `<NOTOPEN>` to an actionable exception

**Files:**
- Modify: `cls/SourceControl/Git/Utils.cls` (add classmethod near `RunGitCommandWithInput`, after line 2249)
- Test: `test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls` (create)

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces:
  - `ClassMethod GitLaunchError(e As %Exception.AbstractException) As %Exception.AbstractException` — returns a `%Exception.General` whose message lists the three causes. If `e.Name '= "<NOTOPEN>"`, returns `e` unchanged.
  - Message text (used by Task 3 assertions) contains the substrings `"git could not be launched"`, `"PATH"`, `"permission"`, and `"Replace a process level token"`. It contains NO `"http"` substring.

- [ ] **Step 1: Write the failing test**

Create `test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls`:

```objectscript
Class UnitTest.SourceControl.Git.Utils.GitLaunchError Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestTranslatesNotOpen()
{
    set src = ##class(%Exception.General).%New("<NOTOPEN>", "", "", "")
    set src.Name = "<NOTOPEN>"
    set translated = ##class(SourceControl.Git.Utils).GitLaunchError(src)
    set msg = translated.DisplayString()
    do $$$AssertTrue(msg [ "git could not be launched", "message explains git launch failed")
    do $$$AssertTrue(msg [ "PATH", "message mentions PATH cause")
    do $$$AssertTrue(msg [ "permission", "message mentions permission cause")
    do $$$AssertTrue(msg [ "Replace a process level token", "message mentions Windows token privilege")
    do $$$AssertTrue('(msg [ "http"), "runtime message contains no docs link")
}

Method TestPassesThroughOtherErrors()
{
    set src = ##class(%Exception.General).%New("<UNDEFINED>", "", "", "")
    set src.Name = "<UNDEFINED>"
    set translated = ##class(SourceControl.Git.Utils).GitLaunchError(src)
    do $$$AssertEquals(translated.Name, "<UNDEFINED>", "non-NOTOPEN error passes through unchanged")
}

}
```

- [ ] **Step 2: Run test to verify it fails**

Run (in the IRIS container terminal for the namespace under test):
```
do ##class(%UnitTest.Manager).RunTest("UnitTest.SourceControl.Git.Utils.GitLaunchError")
```
Expected: FAIL — `GitLaunchError` does not exist (`<METHOD DOES NOT EXIST>`).

- [ ] **Step 3: Write minimal implementation**

In `cls/SourceControl/Git/Utils.cls`, add after `RunGitCommandWithInput` (after line 2249):

```objectscript
/// Translates a &lt;NOTOPEN&gt; error from a failed git launch into an actionable
/// exception listing the known causes. Non-&lt;NOTOPEN&gt; errors are returned unchanged.
ClassMethod GitLaunchError(e As %Exception.AbstractException) As %Exception.AbstractException
{
    if (e.Name '= "<NOTOPEN>") {
        quit e
    }
    set msg = "<NOTOPEN>: git could not be launched. Common causes:"_$c(13,10)
    set msg = msg_" 1. git is not on the IRIS user's PATH (set an absolute path to the git executable in Configure / the Settings page)."_$c(13,10)
    set msg = msg_" 2. The IRIS user lacks permission on the repository directory."_$c(13,10)
    set msg = msg_" 3. Windows: the IRIS user lacks the ""Replace a process level token"" privilege."
    quit ##class(%Exception.General).%New("<NOTOPEN>", , , msg)
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```
do ##class(%UnitTest.Manager).RunTest("UnitTest.SourceControl.Git.Utils.GitLaunchError")
```
Expected: PASS for `TestTranslatesNotOpen` and `TestPassesThroughOtherErrors`.

- [ ] **Step 5: Commit**

```bash
git add cls/SourceControl/Git/Utils.cls test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls
git commit -m "Add GitLaunchError helper to translate <NOTOPEN> git launch failures (#462)"
```

---

### Task 2: Translate `<NOTOPEN>` at the `$zf(-100)` call site

**Files:**
- Modify: `cls/SourceControl/Git/Utils.cls:2172-2184` (the `try/catch` around `$zf(-100)` in `RunGitCommandWithInput`)

**Interfaces:**
- Consumes: `GitLaunchError` from Task 1.
- Produces: `RunGitCommandWithInput` throws the translated exception on `<NOTOPEN>` instead of letting it escape raw. No signature change.

- [ ] **Step 1: Review the current block**

Current code at `cls/SourceControl/Git/Utils.cls:2172-2184`:

```objectscript
    try {
        // Inject instance manager directory as global git config home directory
        // On Linux, this avoids trying to use /root/.config/git/attributes for global git config
        set env("XDG_CONFIG_HOME") = ##class(%File).ManagerDirectory()
        set returnCode = $zf(-100,"/ENV=env... "_baseArgs,gitCommand,newArgs...)
    } catch e {
        if $$$isWINDOWS {
            set returnCode = $zf(-100,baseArgs,gitCommand,newArgs...)
        } else {
            // If can't inject XDG_CONFIG_HOME (older IRIS version), need /SHELL on Linux to avoid permissions errors trying to use root's config
            set returnCode = $zf(-100,"/SHELL "_baseArgs,gitCommand,newArgs...)
        }
    }
```

Note: the outer `catch e` handles the *expected* failure of the `/ENV` variant on older IRIS, then retries. That retry is currently unguarded.

- [ ] **Step 2: Rewrite the block to guard the retry and translate `<NOTOPEN>`**

Replace lines 2172-2184 with:

```objectscript
    try {
        // Inject instance manager directory as global git config home directory
        // On Linux, this avoids trying to use /root/.config/git/attributes for global git config
        set env("XDG_CONFIG_HOME") = ##class(%File).ManagerDirectory()
        set returnCode = $zf(-100,"/ENV=env... "_baseArgs,gitCommand,newArgs...)
    } catch e {
        // /ENV injection failed (older IRIS); retry without it.
        try {
            if $$$isWINDOWS {
                set returnCode = $zf(-100,baseArgs,gitCommand,newArgs...)
            } else {
                // If can't inject XDG_CONFIG_HOME (older IRIS version), need /SHELL on Linux to avoid permissions errors trying to use root's config
                set returnCode = $zf(-100,"/SHELL "_baseArgs,gitCommand,newArgs...)
            }
        } catch retryErr {
            throw ..GitLaunchError(retryErr)
        }
    }
```

Note: the first `$zf(-100)` failing throws into `catch e` and is retried (existing behavior — do not translate it there, since `/ENV` failure is expected on older IRIS). Only the retry's failure is translated. This matches the observed stack in the issue, where the failure surfaced from the retry line.

- [ ] **Step 3: Compile and smoke-test a normal git command**

Compile `SourceControl.Git.Utils`. In a namespace with git correctly configured, run:
```
do ##class(SourceControl.Git.Utils).RunGitCommand("--version",.err,.out) write out.ReadLine(),!
```
Expected: prints `git version ...` (translation path not triggered; normal operation unaffected).

- [ ] **Step 4: Verify translation with a bad git path**

Set an invalid absolute git path, then run a real command:
```
set $namespace = $namespace
set ^["^^%SYS"]... // (skip) — instead use the storage node:
do ##class(SourceControl.Git.Utils).RunGitCommand("status",.err,.out)
```
If a live `<NOTOPEN>` cannot be reliably reproduced in the dev environment, this step is covered by Task 3's `DiagnoseGitLaunch` test; note that here and move on.

- [ ] **Step 5: Commit**

```bash
git add cls/SourceControl/Git/Utils.cls
git commit -m "Translate <NOTOPEN> from git launch retry into actionable error (#462)"
```

---

### Task 3: `DiagnoseGitLaunch` — active probes

**Files:**
- Modify: `cls/SourceControl/Git/Utils.cls` (add classmethod after `GitLaunchError`)
- Test: `test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls` (add methods)

**Interfaces:**
- Consumes: `GitBinPath(.isDefault)` ([Utils.cls:118](../../../cls/SourceControl/Git/Utils.cls#L118)), `TempFolder()` ([Utils.cls:41](../../../cls/SourceControl/Git/Utils.cls#L41)), `RunGitCommand`.
- Produces:
  - `ClassMethod DiagnoseGitLaunch(Output userMessage As %String) As %Boolean` — returns `1` and sets `userMessage=""` when git launches successfully; returns `0` with a diagnostic `userMessage` when it fails.

- [ ] **Step 1: Write the failing test**

Add to `test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls`:

```objectscript
Method TestDiagnoseHealthyWhenGitWorks()
{
    // AbstractTest configures a valid environment; git --version should launch.
    set healthy = ##class(SourceControl.Git.Utils).DiagnoseGitLaunch(.msg)
    do $$$AssertTrue(healthy, "git launches in the test environment")
    do $$$AssertEquals(msg, "", "healthy diagnosis returns empty message")
}

Method TestDiagnoseReportsBadGitPath()
{
    // Point the git bin path at a non-existent absolute path.
    set storage = ##class(SourceControl.Git.Utils).%SYSNamespaceStorage()
    set saved = $get(@storage@("%gitBinPath"))
    try {
        set @storage@("%gitBinPath") = "/nonexistent/path/to/git-binary-xyz"
        set healthy = ##class(SourceControl.Git.Utils).DiagnoseGitLaunch(.msg)
        do $$$AssertNotTrue(healthy, "diagnosis reports unhealthy for bad git path")
        do $$$AssertTrue(msg [ "git", "message references git")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    if (saved = "") {
        kill @storage@("%gitBinPath")
    } else {
        set @storage@("%gitBinPath") = saved
    }
}
```

Note: confirm the storage accessor name — `%SYSNamespaceStorage()` is referenced at `cls/SourceControl/Git/Utils.cls:123`. If the accessor differs, use the exact name found there.

- [ ] **Step 2: Run test to verify it fails**

Run:
```
do ##class(%UnitTest.Manager).RunTest("UnitTest.SourceControl.Git.Utils.GitLaunchError")
```
Expected: FAIL — `DiagnoseGitLaunch` does not exist.

- [ ] **Step 3: Write minimal implementation**

In `cls/SourceControl/Git/Utils.cls`, add after `GitLaunchError`:

```objectscript
/// Actively probes why git cannot be launched. Returns 1 (healthy) with an empty
/// userMessage when git launches; returns 0 with a diagnostic message otherwise.
ClassMethod DiagnoseGitLaunch(Output userMessage As %String) As %Boolean
{
    set userMessage = ""
    // Try a real launch first; if it works, nothing else to report.
    try {
        do ..RunGitCommand("--version", .err, .out)
        if $isobject($get(out)) && (out.ReadLine() [ "git version") {
            quit 1
        }
    } catch e {
        if (e.Name '= "<NOTOPEN>") {
            // Unrelated failure; surface its text but don't run cause probes.
            set userMessage = $system.Status.GetErrorText(e.AsStatus())
            quit 0
        }
    }

    // Launch failed with <NOTOPEN>: probe the known causes.
    set userMessage = "git could not be launched. Diagnosis:"_$c(13,10)
    set binPath = $extract(..GitBinPath(.isDefault), 2, *-1)
    if isDefault {
        set userMessage = userMessage_" - No absolute git path is configured; git is being resolved via the IRIS user's PATH. If git is not on that PATH, set an absolute path in the Settings page."_$c(13,10)
    } elseif '##class(%File).Exists(binPath) {
        set userMessage = userMessage_" - The configured git executable was not found at: "_binPath_$c(13,10)
    } else {
        set userMessage = userMessage_" - The configured git executable exists at "_binPath_" but could not be launched."_$c(13,10)
    }

    set repoDir = ..TempFolder()
    if '##class(%File).DirectoryExists(repoDir) {
        set userMessage = userMessage_" - The repository directory does not exist: "_repoDir_$c(13,10)
    } elseif '..DirectoryWritable(repoDir) {
        set userMessage = userMessage_" - The IRIS user cannot write to the repository directory: "_repoDir_" (check ownership / permissions)."_$c(13,10)
    }

    if $$$isWINDOWS {
        set userMessage = userMessage_" - On Windows, ensure the IRIS user has the ""Replace a process level token"" privilege."_$c(13,10)
    }
    quit 0
}

/// Returns 1 if the IRIS user can create a file in the given directory.
ClassMethod DirectoryWritable(dir As %String) As %Boolean
{
    set probe = ##class(%File).NormalizeFilename(dir_"/.eg-writeprobe")
    set stream = ##class(%Stream.FileCharacter).%New()
    set stream.Filename = probe
    do stream.Write("probe")
    set writable = $$$ISOK(stream.%Save())
    do ##class(%File).Delete(probe)
    quit writable
}
```

Note: verify `..#Slash` vs `/` for `probe`; `%File.NormalizeFilename` handles both separators, so `/` is safe here.

- [ ] **Step 4: Run test to verify it passes**

Run:
```
do ##class(%UnitTest.Manager).RunTest("UnitTest.SourceControl.Git.Utils.GitLaunchError")
```
Expected: PASS for all four methods.

- [ ] **Step 5: Commit**

```bash
git add cls/SourceControl/Git/Utils.cls test/UnitTest/SourceControl/Git/Utils/GitLaunchError.cls
git commit -m "Add DiagnoseGitLaunch active probe for git launch failures (#462)"
```

---

### Task 4: Invoke diagnostics at end of `Configure`

**Files:**
- Modify: `cls/SourceControl/Git/API.cls:25-30` (inside `Configure`, after `Settings.Configure()` succeeds)

**Interfaces:**
- Consumes: `DiagnoseGitLaunch` from Task 3.
- Produces: end-user terminal output when git launch is unhealthy.

- [ ] **Step 1: Add the diagnostic call**

In `cls/SourceControl/Git/API.cls`, after the `tcommit` at line 30 (still inside the `try`), before the closing brace of the `try`, add:

```objectscript
        if '##class(SourceControl.Git.Utils).DiagnoseGitLaunch(.gitDiagMsg) {
            write !,gitDiagMsg
        }
```

The surrounding block becomes:

```objectscript
        set good = ##class(SourceControl.Git.Settings).Configure()
        if 'good {
            write !,"Cancelled."
            quit
        }
        tcommit
        if '##class(SourceControl.Git.Utils).DiagnoseGitLaunch(.gitDiagMsg) {
            write !,gitDiagMsg
        }
```

- [ ] **Step 2: Compile and smoke-test**

Compile `SourceControl.Git.API`. In a namespace with valid git, run:
```
do ##class(SourceControl.Git.API).Configure()
```
(accept defaults). Expected: completes with no diagnostic message printed (git healthy).

- [ ] **Step 3: Verify unhealthy path (optional, manual)**

Temporarily set an invalid git path via the Settings prompt during Configure, or set the storage node as in Task 3's test, then re-run `Configure`. Expected: the diagnostic message prints after configuration.

- [ ] **Step 4: Commit**

```bash
git add cls/SourceControl/Git/API.cls
git commit -m "Run git launch diagnostics at end of Configure (#462)"
```

---

### Task 5: Render diagnostics on the Settings page

**Files:**
- Modify: `csp/gitprojectsettings.csp:285-311` (the git-path fieldset / feedback area)

**Interfaces:**
- Consumes: `DiagnoseGitLaunch` from Task 3.
- Produces: an on-page message near the git-path field when git launch is unhealthy.

- [ ] **Step 1: Add the diagnostic render**

In `csp/gitprojectsettings.csp`, inside the existing `<server>` block around lines 289-310 (which already calls `GitBinExists`), after the feedback variables are computed, add a diagnosis probe and render it below the field. Insert after line 310 (before the closing `</server>`):

```html
                    set gitLaunchHealthy = ##class(SourceControl.Git.Utils).DiagnoseGitLaunch(.gitLaunchMsg)
```

Then, immediately after the closing `</server>` for this block and after the input's feedback `<div>`, add the message rendering:

```html
                <server>
                    if 'gitLaunchHealthy {
                        &html<<div class="alert alert-warning mt-2" style="white-space: pre-line;">#($zconvert(gitLaunchMsg,"O","HTML"))#</div>>
                    }
                </server>
```

Note: `white-space: pre-line;` preserves the `$c(13,10)` line breaks from the message. `$zconvert(...,"O","HTML")` escapes the message for safe HTML output.

- [ ] **Step 2: Load the Settings page and verify (healthy)**

Open the Git project settings page in a namespace with valid git. Expected: no warning alert appears (git healthy).

- [ ] **Step 3: Verify unhealthy path (manual)**

Set an invalid absolute git path via the field and save, or set the storage node as in Task 3's test, then reload the page. Expected: a yellow warning alert with the multi-line diagnosis renders below the git-path field.

- [ ] **Step 4: Commit**

```bash
git add csp/gitprojectsettings.csp
git commit -m "Show git launch diagnostics on the Settings page (#462)"
```

---

### Task 6: README Troubleshooting section

**Files:**
- Modify: `README.md` (add a `## Troubleshooting` section; the `## Support` section begins at line 183, insert before it)

**Interfaces:**
- Consumes: nothing.
- Produces: user-facing docs. Cross-references the existing "Dubious Ownership" (line 117) and "IRIS Privileges" (line 135) subsections.

- [ ] **Step 1: Add the section**

In `README.md`, immediately before the `## Support` heading (line 183), add:

```markdown
## Troubleshooting

### `<NOTOPEN>` error when running git commands

When IRIS cannot launch the git executable, you may see an error like:

```
ERROR #5002: ObjectScript error: <NOTOPEN>RunGitCommandWithInput+151^SourceControl.Git.Utils.1
```

This means the underlying `$zf(-100)` call could not start the git process. Common causes and fixes:

1. **git is not on the IRIS user's PATH.** git may be installed only for your own user account rather than system-wide. Set an absolute path to the git executable in the Configure prompt or on the Settings page (e.g. `C:\Program Files\Git\bin\git.exe` on Windows, `/usr/bin/git` on Unix).
2. **The IRIS user lacks permission on the repository directory.** The namespace temp (repo root) folder must be owned by / accessible to the user IRIS runs as. See [Dubious Ownership](#dubious-ownership).
3. **Windows: the IRIS user lacks the "Replace a process level token" privilege.** Grant this privilege to the account IRIS runs as. See also [IRIS Privileges](#iris-privileges).

For more on `$zf(-100)` error handling, see the [InterSystems documentation](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=RCOS_fzf-100#RCOS_fzf-100_error_handling).

The Configure script and the Settings page also run an automatic diagnostic that reports which of these causes is most likely.
```

- [ ] **Step 2: Verify anchors**

Confirm the markdown anchors `#dubious-ownership` and `#iris-privileges` match the existing headings `#### Dubious Ownership` and `#### IRIS Privileges`. GitHub lowercases and hyphenates heading text for anchors, so these are correct.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document <NOTOPEN> git launch error in README Troubleshooting (#462)"
```

---

### Task 7: Update CHANGELOG

**Files:**
- Modify: `CHANGELOG.md` (add an entry under the unreleased/next section)

**Interfaces:**
- Consumes: nothing.
- Produces: changelog entry.

- [ ] **Step 1: Add the entry**

Open `CHANGELOG.md`, find the top/unreleased section, and add a bullet matching the existing format:

```markdown
- Improved reporting of `<NOTOPEN>` errors on the git executable, with an actionable message and diagnostics pointing to likely causes (#462)
```

Match the exact heading/format already used in the file for the current unreleased entries.

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "Update CHANGELOG for <NOTOPEN> error reporting (#462)"
```

---

## Self-Review

**Spec coverage:**
- Catch & translate `<NOTOPEN>` → Tasks 1, 2. ✓
- On-demand active diagnostics (end of Configure + Settings load) → Tasks 3, 4, 5. ✓
- Troubleshooting docs in README with the InterSystems link → Task 6. ✓
- Logging explicitly out of scope → no task. ✓ (consistent with spec)
- Runtime message has no docs link → enforced by Global Constraints and Task 1 test `TestTranslatesNotOpen` (`msg` contains no `"http"`). ✓
- Link appears in README only → Task 6. ✓

**Placeholder scan:** Task 2 Step 4 notes a live `<NOTOPEN>` may be hard to reproduce and defers to Task 3's test — this is a conditional verification note, not a code placeholder; acceptable. No "TBD"/"TODO" in delivered code.

**Type consistency:**
- `GitLaunchError(e)` — defined Task 1, consumed Task 2. ✓
- `DiagnoseGitLaunch(.userMessage)` returning `%Boolean` — defined Task 3, consumed Tasks 4, 5. ✓
- `DirectoryWritable(dir)` helper — defined and used within Task 3. ✓
- Storage accessor `%SYSNamespaceStorage()` referenced in Task 3 test — flagged to verify against `Utils.cls:123`. ✓
