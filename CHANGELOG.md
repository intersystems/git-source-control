# git-source-control

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.3.1] - Unreleased

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

