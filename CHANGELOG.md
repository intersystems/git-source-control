# git-source-control

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.4.1] - Unreleased

### Added
- New API endpoint that accepts git commands as array instead of string (#437)

### Fixed
- Fixed JS errors in Studio on certain operations (#416)
- Add menu option disabled for unsaved files (#420)
- Fixed issue where selecting different item in stash list didn't update diff view (#265)
- Tooltip in workspace now shows user who made uncommitted change if not current user (#411)
- Files are added to source control upon creation properly (#404)
- Files show in uncommitted queue when automatically added (#407)
- WebUI workspace view now works properly for filenames with spaces (#423)
- Fixed error popups in interop editors in Studio on 2024.1 (#417)
- Reintroduced amend (#425)
- Git operations that import items into IRIS now report output from compilation (#426)
- Double quotes now permissible in commit messages (#433)

## [2.4.0] - 2024-07-08

### Added
- Pre-release support for IPM v0.9.0+
- Items mapped from database other than namespace's default routine database are now ignored by default when exporting or adding files
- New setting to configure whether mapped items should be should be treated as read-only
- Added a basic mode to automatically perform functionality expected in basic use cases (#349)
- New sync operation for basic mode that fetches, pulls, commits, pushes, rebases, and pushes again (#349)
- "Sync" operation in basic mode automatically resolves the class of merge conflict common in production classes where multiple independent items are added in different feature branches
- Now skips files belonging to other git enabled packages in `##class(SourceControl.Git.Change).RefreshUncommitted()` (#347)
- Added a new "Branch" parameter to `##class(SourceControl.Git.PullEventHandler)` (#351)
- Command-line utility to do a baseline export of items in a namespace
- 'New Branch' menu option in basic now will create new branches from the configured default merge branch (#366)
- Merging back with the default merge branch is now a part of the basic mode's Sync flow (#366)
- Added a new option "compileOnImport". If true, Import options will compile files using the pull event handler. (#362)
- Git web UI overhauled for better UX selecting files to commit/stash/discard (#346)
- Git web UI supports discarding some/all changes (#395)

### Fixed
- Modifications to local repo files are now synced with IRIS (#153)
- Menu items names are properly translated from internal name in VSCode, Management Portal (#372)
- Now has proper locking behavior in `##class(SourceControl.Git.WebUIDriver).HandleRequest()`(#385)
- Git operations from the WebUI now don't unlock the session if they aren't read-only
- WebUI works properly for users with %Developer without needing to add further SQL privileges (#365, #358)
- Uncommitted deletes are shown in WebUI (#395)
- Syncing only prompts users for a commit message if there are uncommitted files (#390)
- WebUI works properly for users with %Developer without needing to add further SQL privileges (#365)
- Fixed `<UNDEFINED>` error running Import All (#380)
- Discarding changes now recompiles - critical for productions and some other cases (#387)
- Special characters in WebUI git commands now result in the command being executed properly (#369)

## [2.3.1] - 2024-04-30

### Fixed
- Support for git submodules in package manager-aware setting (#305)
- Web UI's 'More ...' view shows longer branch names (#294)
- Deletion of files in locked environment is now suppressed (#302)
- Failed to import file VS Code popup no longer shows up after overwriting file on server once (#264)
- Don't automatically stage files added to source control (#303)
- Performance improvements (#269, #315)
- Checkout of branches whose names contain slashes via Web UI no longer fails (#295)
- Display other developer's username in Web UI's Workspace when hovering over the name of a file they changed (#304)
- Incremental load PullEventHandler now handles file deletion (#299)
- Incremental load PullEventHandler no longer returns a Success Status if an error was thrown during the pull process (#300)
- CSP applications can now be added to Git successfully (#308)

## [2.3.0] - 2023-12-06

### Added
- Web UI includes a "Push Branch" button for local branches that are ahead of upstream
- Support for making the Settings UI read-only through `##class(SourceControl.Git.API).Configure()` (#258)
- Stash option in the Web UI now includes untracked files
- Added "Status" menu item to editor menu (#285)

### Fixed
- Fatal: bad revision HEAD fixed using an empty commit (#228)
- Fixed empty mappings when SourceControl.Git.Settings is instantiated (#250)
- Studio export path doesn't get weird mixed slahes on Windows (#252)
- Fixed custom PullHandlers not visible on settings UI (now all subclasses are visible) (#267)
- Fixed bug with adding mappings through the Settings page (#270)
- Pulling add/delete of multiple non-IRIS files no longer causes error (#273)
- Fixed -2 timestamp for some items (#275)
- Reset SourceControlClass during module uninstall to prevent "Class does not exist error" (#285)
- Unreleased bug breaking Git WebUI from Studio (#297)

## [2.2.0] - 2023-06-05

### Added
- Page to support deployment (git pull and run pull event handler) with verbose output
- Support for git clone to initialize namespace via Settings page and `##class(SourceControl.Git.API).Configure()` (#234, #237)
- Support for automatically creating SSH keys for use as deploy keys via Settings page and `Configure()` (#33)

### Fixed
- Protect against Favorites links containing control characters (#254)
- Green checks for valid paths shown consistently (#229)

## [2.1.1] - 2023-02-24

### Fixed
- Link from WebUI to Settings page works properly (#230)
- No longer get a "permission denied" message on Linux (#231)
- VSCode Web Views launch in external browser when connecting over unsecured connections (#227)
- DTL/BPL editing through Studio reflected properly in source control (#241)
- Plays nicely with interoperability "Deployment" features (#236)
- `<PROTECT>` errors rendering menus as a user with limited privileges (%Developer + Ens*)

## [2.1.0] - 2023-01-23

### Added
- Support for Caché/Ensemble 2016.2.3, 2017.1.2, 2017.2.1, 2018.1.0 and later.
- Installation adds a Management Portal favorite for all users (#209)
- Improved configuration and defaults to simplify initial configuration (#213)
  - If no name/email is specified, defaults to `$username` and `$username@<hostname>`

### Fixed
- "Import All" will properly recognize new files
- "Import All" and "Export All" apply only to the current package manager context and disregard items outside that context
- "Import All" treats "Other" document types (DFI, LUT, etc.) properly

### Internal
- Added CI script and tweaked unit tests to run properly in a container and bootstrap their own extension configuration
- Tweaked various minor things under the hood to support use without the package manager and/or on older platforms

## [2.0.5] - 2022-12-02

### Fixed
- Tree/Commit links don't navigate
- Slashes present in tree view

### Security
- File contents are properly escaped in tree view

## [2.0.4] - 2022-10-05

### Fixed
- Properly handles UTF-8 characters in Git commit messages

## [2.0.3] - 2022-09-07

### Fixed
- Correctly detects filesystem mappings in a package manager context
- Improved performance by removing redundant git status calls

## [2.0.2] - 2022-08-09

### Fixed
- #201: fix behavior with CSP files

## [2.0.1] - 2022-06-02
- Last released version before CHANGELOG existed.

