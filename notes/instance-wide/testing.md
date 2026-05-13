# Instance-Wide Source Control Testing Plan

This plan tests an [instance-wide Embedded Git configuration](../../docs/instance-wide.md).

The setup simulates a multi-namespace IRIS instance where all namespaces share a
single routines database (HSCUSTOM) and a single Git repository, with source control
configuration stored in a dedicated CONFIG database.

## Prerequisites

- IRIS dev container is running (`iris` hostname from workspace container)
- Embedded Git (git-source-control) is loaded in dev mode in the USER namespace
- SSH access: `ssh -i /workspace/.devcontainer/.ssh/dev_key irisowner@iris 'iris session iris'`
- Management Portal: http://localhost:52774/csp/sys/UtilHome.csp (user: `_SYSTEM`, pass: `SYS`)

## Phase 1: Create Databases

Create the two new databases required by the instance-wide approach.

### Step 1.1 — Create the CONFIG database

```objectscript
zn "%SYS"

// Create directory and database for source control configuration
set configDir = "/usr/irissys/mgr/config/"
do ##class(%File).CreateDirectoryChain(configDir)
set props("Directory") = configDir
set sc = ##class(SYS.Database).CreateDatabase(configDir, 10)
write "CreateDatabase CONFIG: ", $system.Status.GetErrorText(sc), !
set sc = ##class(Config.Databases).Create("CONFIG", .props)
write "Register CONFIG: ", $system.Status.GetErrorText(sc), !
```

**Verify:** Navigate to System Administration > Configuration > System Configuration > Local Databases
in the Management Portal. CONFIG should appear in the list.

### Step 1.2 — Create the HSCUSTOM database (shared routines)

```objectscript
zn "%SYS"

set hscustomDir = "/usr/irissys/mgr/hscustom/"
do ##class(%File).CreateDirectoryChain(hscustomDir)
set props("Directory") = hscustomDir
set sc = ##class(SYS.Database).CreateDatabase(hscustomDir, 100)
write "CreateDatabase HSCUSTOM: ", $system.Status.GetErrorText(sc), !
set sc = ##class(Config.Databases).Create("HSCUSTOM", .props)
write "Register HSCUSTOM: ", $system.Status.GetErrorText(sc), !
```

## Phase 2: Create Test Namespaces

Create two additional namespaces (NS-A, NS-B) to simulate a multi-namespace instance.
Each gets its own globals (data) database but shares HSCUSTOM for routines.

### Step 2.1 — Create data databases for each namespace

```objectscript
zn "%SYS"

// Data database for NS-A
set dir = "/usr/irissys/mgr/data-a/"
do ##class(%File).CreateDirectoryChain(dir)
set sc = ##class(SYS.Database).CreateDatabase(dir, 50)
write "CreateDatabase DATA-A: ", $system.Status.GetErrorText(sc), !
set props("Directory") = dir
set sc = ##class(Config.Databases).Create("DATA-A", .props)
write "Register DATA-A: ", $system.Status.GetErrorText(sc), !

// Data database for NS-B
set dir = "/usr/irissys/mgr/data-b/"
do ##class(%File).CreateDirectoryChain(dir)
set sc = ##class(SYS.Database).CreateDatabase(dir, 50)
write "CreateDatabase DATA-B: ", $system.Status.GetErrorText(sc), !
set props("Directory") = dir
set sc = ##class(Config.Databases).Create("DATA-B", .props)
write "Register DATA-B: ", $system.Status.GetErrorText(sc), !
```

### Step 2.2 — Create namespaces pointing to HSCUSTOM for routines

```objectscript
zn "%SYS"

// NS-A: globals in DATA-A, routines in HSCUSTOM
set props("Globals") = "DATA-A"
set props("Routines") = "HSCUSTOM"
set sc = ##class(Config.Namespaces).Create("NS-A", .props)
write "Create NS-A: ", $system.Status.GetErrorText(sc), !

// NS-B: globals in DATA-B, routines in HSCUSTOM
kill props
set props("Globals") = "DATA-B"
set props("Routines") = "HSCUSTOM"
set sc = ##class(Config.Namespaces).Create("NS-B", .props)
write "Create NS-B: ", $system.Status.GetErrorText(sc), !
```

### Step 2.3 — Enable interoperability for each namespace

This enables Interoperability features in the namespaces.

```objectscript
zn "%SYS"
set sc = ##class(%Library.EnsembleMgr).EnableNamespace("NS-A", 1)
write "Enable NS-A for interoperability: ", $system.Status.GetErrorText(sc), !
set sc = ##class(%Library.EnsembleMgr).EnableNamespace("NS-B", 1)
write "Enable NS-B for interoperability: ", $system.Status.GetErrorText(sc), !
```

**Verify:**
```objectscript
zn "%SYS"
// Confirm routines database for each namespace
write ##class(%SYS.Namespace).GetRoutineDest("NS-A"), !
write ##class(%SYS.Namespace).GetRoutineDest("NS-B"), !
// Both should show the HSCUSTOM directory path
```

## Phase 3: Migrate USER Namespace to HSCUSTOM

The USER namespace currently has its code in the USER database. For a true instance-wide
setup, USER should also use HSCUSTOM for routines.

### Step 3.1 — Switch USER routines database to HSCUSTOM

```objectscript
zn "%SYS"

// Change USER namespace routines database to HSCUSTOM
set sc = ##class(Config.Namespaces).Get("USER", .props)
set props("Routines") = "HSCUSTOM"
set sc = ##class(Config.Namespaces).Modify("USER", .props)
write "Modify USER routines to HSCUSTOM: ", $system.Status.GetErrorText(sc), !
```

### Step 3.2 — Reload git-source-control into HSCUSTOM

After switching the routines database, the git-source-control classes need to be
reloaded so they are compiled into HSCUSTOM.

```objectscript
zn "USER"
zpm "load /home/irisowner/dev/git-source-control/ -dev -verbose"
```

**Verify:**
```objectscript
zn "USER"
write ##class(SourceControl.Git.Utils).%ClassName(1), !
// Expected: SourceControl.Git.Utils
```

### Step 3.3 — Map git-source-control classes to %ALL

After installing in one namespace, call `MapEverywhere` to create the %ALL package
mapping so the `SourceControl.Git` classes are accessible from every namespace.

```objectscript
zn "USER"
set sc = ##class(SourceControl.Git.API).MapEverywhere()
write "MapEverywhere: ", $system.Status.GetErrorText(sc), !
```

> **Note:** `MapEverywhere` creates a %ALL package mapping for `SourceControl.Git`
> but not for `%zpkg.isc.sc.git` (helper classes used by Settings and Utils).
> Add that mapping manually:

```objectscript
zn "%SYS"
// Find which database the %zpkg classes are in
set sc = ##class(Config.MapPackages).Get("USER", "%zpkg.isc.sc.git", .props)
write "%zpkg.isc.sc.git in USER -> ", props("Database"), !

// Create the %ALL mapping pointing to the same database
kill newProps
set newProps("Database") = props("Database")
set sc = ##class(Config.MapPackages).Create("%All", "%zpkg.isc.sc.git", .newProps)
write "Create %ALL %zpkg.isc.sc.git: ", $system.Status.GetErrorText(sc), !
```

**Verify:**
```objectscript
zn "NS-A"
write ##class(SourceControl.Git.Utils).%ClassName(1), !
// Expected: SourceControl.Git.Utils
```

## Phase 4: Configure Global Mappings

### Step 4.1 — Map source control configuration globals to CONFIG

These mappings go into %ALL so every namespace reads/writes source control config
from the same CONFIG database.

```objectscript
zn "%SYS"

// Map SYS("SourceControl") to CONFIG for all namespaces
set props("Database") = "CONFIG"
set sc = ##class(Config.MapGlobals).Create("%All", "SYS(""SourceControl"")", .props)
write "Map SYS(SourceControl): ", $system.Status.GetErrorText(sc), !

kill props
set props("Database") = "CONFIG"
set sc = ##class(Config.MapGlobals).Create("%All", "SYS(""SourceControlClass"")", .props)
write "Map SYS(SourceControlClass): ", $system.Status.GetErrorText(sc), !

kill props
set props("Database") = "CONFIG"
set sc = ##class(Config.MapGlobals).Create("%All", "Studio.SourceControl*", .props)
write "Map Studio.SourceControl*: ", $system.Status.GetErrorText(sc), !
```

### Step 4.2 — Map interoperability/localization globals to HSCUSTOM

These are the globals listed in the doc that store production configuration,
lookup tables, HL7 schemas, etc.

```objectscript
zn "%SYS"

set globals = $listbuild( "Ens.Config.Item*", "Ens.Config.Production*", "Ens.Rule", "Ens.Rule.Targets", "Ens.Config.BusinessPartner*", "Ens.Config.DefaultSettings*", "Ens.LookupTable", "Ens.Util.Schedule*", "EnsEDI.Description", "EnsEDI.Schema", "EnsEDI.X12.Description", "EnsEDI.X12.Schema", "EnsEDI.ASTM.Description", "EnsEDI.ASTM.Schema", "EnsHL7.Description", "EnsHL7.Schema", "Ens.Conf.Credentials*", "Ens.SecondaryData.Password", "IRIS.Msg", "IRIS.MsgNames")

for i=1:1:$listlength(globals) { set global = $listget(globals, i) kill props set props("Database") = "HSCUSTOM" set sc = ##class(Config.MapGlobals).Create("%ALL", global, .props) write "Map ", global, ": ", $system.Status.GetErrorText(sc), !  }
```

> **Note:** Some of these mappings may already exist because of MapEverywhere. That is fine.

**Verify:**

To verify the mapping works, write a value in one namespace and read it from another.

```objectscript
zn "USER"
set ^SYS("SourceControl","verify-mapping") = "from-USER"

zn "NS-A"
write $get(^SYS("SourceControl","verify-mapping"), "NOT FOUND"), !
// Expected: from-USER

zn "NS-B"
write $get(^SYS("SourceControl","verify-mapping"), "NOT FOUND"), !
// Expected: from-USER

// Clean up
zn "USER"
kill ^SYS("SourceControl","verify-mapping")
```

## Phase 5: Configure Embedded Git (Instance-Wide)

### Step 5.1 — Set source control class in one namespace

Since the SYS("SourceControlClass") global is now mapped to CONFIG (shared), setting
it in any namespace sets it for all namespaces.

```objectscript
zn "USER"
do ##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension")
```

**Verify across namespaces:**
```objectscript
zn "NS-A"
write ##class(%Studio.SourceControl.Interface).SourceControlClassGet(), !
// Expected: SourceControl.Git.Extension

zn "NS-B"
write ##class(%Studio.SourceControl.Interface).SourceControlClassGet(), !
// Expected: SourceControl.Git.Extension
```

### Step 5.2 — Initialize a shared Git repository

Create a single repo directory that all namespaces will share.

```objectscript
zn "USER"
set settings = ##class(SourceControl.Git.Settings).%New()
set settings.namespaceTemp = "/home/irisowner/shared-repo/"
set settings.gitUserName = "Test User"
set settings.gitUserEmail = "test@example.com"
set settings.decomposeProductions = 0
set sc = settings.%Save()
write "Save settings: ", $system.Status.GetErrorText(sc), !
```

Then initialize the git repo:
```objectscript
zn "USER"
do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("config",,,,"--global","--add","safe.directory","/home/irisowner/shared-repo")
set workMgr = $System.WorkMgr.%New("")
set sc = workMgr.Queue("##class(SourceControl.Git.Utils).Init")
write "Queue Init: ", $system.Status.GetErrorText(sc), !
set sc = workMgr.WaitForComplete()
write "Init complete: ", $system.Status.GetErrorText(sc), !
```

**Verify:**
```objectscript
// The repo should be visible from all namespaces since the settings global is shared
zn "NS-A"
write ##class(SourceControl.Git.Utils).TempFolder(), !
// Expected: /home/irisowner/shared-repo/

zn "NS-B"
write ##class(SourceControl.Git.Utils).TempFolder(), !
// Expected: /home/irisowner/shared-repo/
```

## Phase 6: Functional Tests

### Test 6.1 — Create a class in NS-A, see it from NS-B

Since both namespaces share HSCUSTOM as their routines database, a class compiled
in one namespace should be visible in the other.

```objectscript
zn "NS-A"

// Create and compile a test class
set clsDef = ##class(%Dictionary.ClassDefinition).%New("Test.SharedClass")
set clsDef.Super = "%RegisteredObject"
set method = ##class(%Dictionary.MethodDefinition).%New()
set method.Name = "Hello"
set method.ReturnType = "%String"
set method.Implementation.WriteLine("    quit ""Hello from shared class""")
do clsDef.Methods.Insert(method)
set sc = clsDef.%Save()
write "Save: ", $system.Status.GetErrorText(sc), !
set sc = $system.OBJ.Compile("Test.SharedClass", "ck")
write "Compile: ", $system.Status.GetErrorText(sc), !
write "Created Test.SharedClass in NS-A", !
```

```objectscript
zn "NS-B"
// This class should be visible because NS-B also uses HSCUSTOM for routines
set obj = ##class(Test.SharedClass).%New()
write obj.Hello(), !
// Expected: Hello from shared class
```

### Test 6.2 — Export from NS-A, verify file appears in shared repo

```objectscript
zn "NS-A"
// Trigger source control export for the new class
set sc = ##class(SourceControl.Git.Utils).AddToSourceControl("Test.SharedClass.CLS")
write "AddToSourceControl: ", $system.Status.GetErrorText(sc), !
```

Then check the filesystem:
```bash
ssh -i /workspace/.devcontainer/.ssh/dev_key irisowner@iris \
  'ls -la /home/irisowner/shared-repo/cls/Test/'
# Expected: SharedClass.cls file exists
```

### Test 6.3 — Git status shows changes from any namespace

```objectscript
zn "NS-A"
do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("status",,.errStream,.outStream)
do outStream.Rewind()
write outStream.Read(), !

zn "NS-B"
do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("status",,.errStream,.outStream)
do outStream.Rewind()
write outStream.Read(), !
// Both should show the same git status (same repo)
```

### Test 6.4 — Commit from NS-A, verify log from NS-B

```objectscript
zn "NS-A"
set sc = ##class(SourceControl.Git.Utils).Commit("Test.SharedClass.CLS", "Add shared test class")
write "Commit: ", $system.Status.GetErrorText(sc), !
```

```objectscript
zn "NS-B"
do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("log",,.errStream,.outStream,"--oneline","-5")
do outStream.Rewind()
write outStream.Read(), !
// Should show "Add shared test class" commit
```

### Test 6.5 — Instance-wide locking via shared uncommitted queue

Because all namespaces share the HSCUSTOM routines database, the
`SourceControl_Git.Change` table (the uncommitted queue) is also shared.
This means the normal Embedded Git locking mechanism works instance-wide
without any special configuration — if User A edits a file in NS-A, User B
in NS-B will see it as checked out and locked.

Source control hooks are triggered by editors (Management Portal, VS Code, Studio),
not by raw terminal `%Save()`/`$system.OBJ.Compile()` calls. This test uses
the Management Portal's Business Rule Editor, which does invoke the hooks.

**Setup — Create a second IRIS user and a simple business rule:**

```objectscript
zn "%SYS"
set props("NameSpace") = "NS-B"
set props("Roles") = "%All"
set props("Password") = "SYS"
set sc = ##class(Security.Users).Create("testuser2", .props)
write "Create testuser2: ", $system.Status.GetErrorText(sc), !
```

Create a business rule to use as the test item:

```objectscript
zn "NS-A"

set clsDef = ##class(%Dictionary.ClassDefinition).%New("Test.SampleRule")
set clsDef.Super = "Ens.Rule.Definition"
set xdata = ##class(%Dictionary.XDataDefinition).%New()
set xdata.Name = "RuleDefinition"
do xdata.Data.WriteLine("<ruleDefinition>")
do xdata.Data.WriteLine("<ruleSet effectiveBegin="""" effectiveEnd="""">")
do xdata.Data.WriteLine("<rule name=""Rule1"">")
do xdata.Data.WriteLine("<when condition=""1"">")
do xdata.Data.WriteLine("<return value=""pass""/>")
do xdata.Data.WriteLine("</when>")
do xdata.Data.WriteLine("</rule>")
do xdata.Data.WriteLine("</ruleSet>")
do xdata.Data.WriteLine("</ruleDefinition>")
do clsDef.XDatas.Insert(xdata)
set sc = clsDef.%Save()
write "Save: ", $system.Status.GetErrorText(sc), !
set sc = $system.OBJ.Compile("Test.SampleRule", "ck")
write "Compile: ", $system.Status.GetErrorText(sc), !

set sc = ##class(SourceControl.Git.Utils).AddToSourceControl("Test.SampleRule.CLS")
write "AddToSourceControl: ", $system.Status.GetErrorText(sc), !
set sc = ##class(SourceControl.Git.Utils).Commit("Test.SampleRule.CLS", "Add sample rule for lock test")
write "Commit: ", $system.Status.GetErrorText(sc), !
```

**Step 1 — User `_SYSTEM` edits the rule in NS-A via the Management Portal:**

1. Open the Management Portal: http://localhost:52774/csp/sys/UtilHome.csp
2. Log in as `_SYSTEM` / `SYS`
3. Switch to namespace **NS-A** (using the namespace switcher)
4. Navigate to **Interoperability > Build > Business Rules**
5. Open `Test.SampleRule`
6. Make a change (e.g. edit the return value from `pass` to `approved`) and **Save**
7. The rule editor invokes `OnAfterSave`, which calls `SetUncommitted` — this
   records `_SYSTEM` as the user with uncommitted changes

**Verify the uncommitted entry was created:**

```objectscript
zn "NS-A"
set filename = ##class(SourceControl.Git.Utils).FullExternalName("Test.SampleRule.CLS")
write "Is uncommitted: ", ##class(SourceControl.Git.Change).IsUncommitted(filename), !
// Expected: 1
set sc = ##class(SourceControl.Git.Change).GetUncommitted(filename, .action, .intName, .user)
write "Uncommitted user: ", user, !
// Expected: _SYSTEM
```

**Step 2 — User `testuser2` tries to edit the same rule in NS-B:**

1. Open a second browser (or incognito window): http://localhost:52774/csp/sys/UtilHome.csp
2. Log in as `testuser2` / `SYS`
3. Switch to namespace **NS-B**
4. Navigate to **Interoperability > Build > Business Rules**
5. Open `Test.SampleRule`
6. The rule should appear as **read-only / checked out by `_SYSTEM`** because
   `GetStatus` sees the uncommitted queue entry made by `_SYSTEM` in step 1

**Step 3 — Commit as `_SYSTEM` and verify the lock releases:**

Back in the first browser (as `_SYSTEM`):
1. Use the Git source control menu (from NS-A or any namespace) to **Commit** the change
2. Or commit from terminal:

```objectscript
zn "NS-A"
set sc = ##class(SourceControl.Git.Utils).Commit("Test.SampleRule.CLS", "Update sample rule")
write "Commit: ", $system.Status.GetErrorText(sc), !
```

Now in the second browser (as `testuser2` in NS-B):
1. Refresh or re-open `Test.SampleRule` in the Business Rule Editor
2. The rule should now be **editable** — the uncommitted queue entry was cleared
   by the commit, so `GetStatus` no longer reports it as checked out

## Phase 7: Settings Sharing Verification

### Test 7.1 — Settings saved in one namespace are visible in all

```objectscript
zn "USER"
set settings = ##class(SourceControl.Git.Settings).%New()
set settings.pullEventClass = "SourceControl.Git.PullEventHandler.IncrementalLoad"
set sc = settings.%Save()
write "Save: ", $system.Status.GetErrorText(sc), !
```

```objectscript
zn "NS-A"
set settings = ##class(SourceControl.Git.Settings).%New()
write "pullEventClass from NS-A: ", settings.pullEventClass, !
// Expected: SourceControl.Git.PullEventHandler.IncrementalLoad

zn "NS-B"
set settings = ##class(SourceControl.Git.Settings).%New()
write "pullEventClass from NS-B: ", settings.pullEventClass, !
// Expected: SourceControl.Git.PullEventHandler.IncrementalLoad
```

## Summary Checklist

| # | Test | Expected Result |
|---|------|-----------------|
| 6.1 | Class created in NS-A visible in NS-B | Shared routines DB works |
| 6.2 | Export from NS-A writes to shared repo | Single repo for all namespaces |
| 6.3 | Git status identical from any namespace | Shared repo config |
| 6.4 | Commit from NS-A, log visible in NS-B | Shared git history |
| 6.5 | Edit locking across namespaces via shared uncommitted queue | Item locked by User A in NS-A is non-editable for User B in NS-B; lock releases after commit |
| 7.1 | Settings shared across namespaces | CONFIG DB mapping works |
| 7.2 | Mappings shared across namespaces | CONFIG DB mapping works |