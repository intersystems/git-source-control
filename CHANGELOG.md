# git-source-control

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.13.0] - Unreleased

### Fixed
- Fix Import All not importing items that do not already exist when compileOnImport is not set (#798)
- Import All now imports configuration file before everything else (#806)
- Fix Revert not syncing files with IRIS (#789)

## [2.12.2] - 2025-07-08

### Fixed
- Fixed importing Lookup Tables that do not already exist (#791)
- Fix initial import of settings file that has yet to be imported (#794)
- Fixed syncing IRIS with files after pull to diff in the intended direction (#802)

## [2.12.1] - 2025-06-27

### Fixed
- Fixed an edge case installing the package on containers with Durable SYS (#795)

## [2.12.0] - 2025-06-06

### Added
- Expanded Baseline Export to include custom HL7, X12, ASTM schemas and Lookup Tables (#693)
- Mapping configuration expands \<namespace\> and \<token\> parameters to better support multi-namespace solutions (#710)
- Settings page includes a test of the connection to the remote (#746)

### Fixed
- Deletes are now properly owned by the user who did the delete (#729)
- Pull page output now displays better when pull preview shows a lot of changes (#740)
- Extensions in item cache are consistently upper-case, so "export all" doesn't duplicate work (#727)
- Fixed loop of loading classes with compilation errors in Studio (#766)
- Fixed error popup when creating new record map or other interop items (#753)
- Changing remotes in the git project settings pages now works if remote is not already defined (#746)
- User-specific basic mode setting can now be changed when settingsUIReadOnly is set (#775)
- Fixed an error displaying the Web UI after reverting a commit (#776)
- Fixed checkout of a remote branch not syncing files with IRIS (#783)
- Fixed errors exporting items when directory casing does not match mappings (#781)
- Improved accessibility of UI when tabbing through items (#764)

## [2.11.0] - 2025-04-23

### Added
- Pull event handler that does an IPM uninstall and load to handle deletes (#631)
- Partial support for production decomposition with the new interoperability editors
- Added Lock Branch setting to prevent switching branches for a protected namespace (#709)
- Tooltips on branch operations in Git UI (#725)

### Fixed
- Changing system mode (environment name) in settings persists after instance restart (#655)
- Popping from stash is more responsive (#687, #747)
- Favorites links for Git pages now works on recent IRIS versions (#734)
- IDE editing of decomposed productions now properly handles adds and deletes (#643)
- Fixed error running Import All when Git settings file does not exist (#713)

## [2.10.0] - 2025-02-10

### Added
- LoadProductionsFromDirectory method to help custom deployment scripts load decomposed productions from the repository (#670)
- Added ability to reset head / revert most recent commit (#586)
- Changes deployed through Git are now logged in a new table SourceControl_Git.DeploymentLog

### Fixed
- Fixed not showing warnings on Studio (#660)
- Fixed business processes and rules not being added to source control automatically (#676)
- Embedded Git commits settings when cloning empty repo to avert any issues
- Fixed Import All options not importing the Embedded Git configuration file
- That configuration file now imports before everything else (#697)
- Improved performance of IDE editing and baselining of decomposed productions
- Fixed Discard / Stash not working on deletes (#688)
- Fixed errors deploying decomposed production changes on Windows network drives (#696)
- Improved performance of deploying changes to decomposed production items (#690)
- Fixed errors saving decomposed productions when invalid items in item cache (#701)
- Removed unnecessary Add and Remove menu items from decomposed productions (#701)

## [2.9.0] - 2025-01-09

### Added
- Menu option to export production to support migrating to production decomposition (#665)

### Fixed
- Fixed errors on production page when item settings need to be XML escaped (#667)
- Fixed push button not appearing after commit (#654)
- Fixed merge conflict resolution on stash popping (#531)
- Improvements to the performance of the instance-wide uncommitted check (#674)
- Fix "Max $ZF String" error when committing lots of files (#617)

## [2.8.0] - 2024-12-06

### Added
- Production Decomposition mode allows controlling interoperability productions as individual files for each host (#469)
- Mapping configuration supports parameter expansion of \<env\> to the environment name (#640)
- Added saving settings as system default for new namespaces (#535)
- Added filtering through branch names in UI (#615)
- FullLoad pull event handler allows deploying changes with a full import of the repository (#619)
- Pull and Sync options no longer log a fatal error if remote branch does not exist (#562)

### Fixed
- Fixed minor issues in Studio UI (#641)
- Document save is forced before menu operations that can modify repository state

## [2.7.1] - 2024-11-13

### Fixed
- Fixed improper encoding of unicode characters in commit messages (#627)
- Creating a new branch now reports the error if uncommitted changes conflict (#624)
- Fix Configure erroring out if git isn't found (#632)
- Fix "%" replacing characters in lookup table names (#588)

## [2.7.0] - 2024-11-04

### Added
- Added 'git push --force' in expert mode (#527)
- Add remote repository to settings page (#448)
- Added change context option to pull page (#468)
- Added favorite namespaces setting for a user (#468, #510) 
- Added environment awareness in configuration, and showing of environment name in UI (#124)
- Warning on sync page if other users have unstaged changes (#493)
- Added "Export System Default Settings" menu item (#544)
- IRIS Business Intelligence items are mapped to the /dfi subdirectory by default (#428)
- Intelligent merge conflict auto-resolution works for the common Business Rule case as well (#391)
- All git commands run on the server, their output, and any associated sync output, are logged to a table for diagnostic purposes (#454)
- Added API method to automatically add proper %ALL mappings for git-source-control (#214)

### Fixed
- Fixed display of other users' username in workspace view on Unix (#530)
- Fix left-sidebar spacing (#525)
- Fixed slowness loading some CSP pages with multiple instances sharing a webserver (#540)
- Prevent direct commits to default merge branch in basic mode (#484)
- Fixed GetContexts utils function to exclude implied namespaces from the list of namespaces (#468)
- Fixed git path configuration (#463)
- Added feedback to settings page (#550)
- Fix "Home" navigation to point to current namespace (#548)
- Fixed issues when user checks out nonexistent branch (#549)
- Fixed checking out branch with uncommitted work (#539)
- Make sure more fetch calls prune the remote branches (#471)
- Force export of item if it has been modified (#354)
- Production configuration page no longer closes Sync/WebUI when operations there change the production (#542)
- Remove leading/trailing spaces from input to Configure() (#356)
- Fix branches with special characters not showing in GitUI (#523)
- Fix filenames with spaces not showing correctly in workspace view (#551)
- Removed inaccurate placeholder text for commit message in UI (#406)
- Fixed regression that broke production conflict auto-resolve (#526)
- Initialize repo in settings page now uses entered repo (#486)
- Report error more clearly if you try to create a branch with an invalid name (#534)
- Don't default to WINDOWS style paths (#357)
- Fix errors when deleting non-existent files on import (#524)
- Fix errors on commit when a file was added, never committed, then deleted from the repository (#481)
- Fixed issue with saving multiple new no-folder mapping settings at the same time (#533)
- Fixed sending OS error when git pull encounters error (#545)
- Fixed suppressing editing of locked classes (#301)
- Fixed importing CSP files (#251)
- Fixed changing favorites for users without permissions (#587)
- Fix creating new branch from Git Web UI (#591)
- Fix wording for Git Repo Root Directory (#601)
- Fix Diff View options not applying immediately (#590)
- Cleaned up parsing of command output in Git Web UI (#609)
- Fix TempFolder misspecification (#611)
- Fix deleting files on import all (#618)

## [2.6.0] - 2024-10-07

### Added
- Discards safeguarded by discard stash and warning modal (#455)
- Files in uncommitted queue in any namespace warn users when opened except for in VSCode (#370)
- Added link back to IRIS management portal from Settings, Git WebUI pages (#449)
- Added Import all and Import All (Force) to basic mode menu (#498)
- Improved behavior for commits when attribution settings are not configured (#450)
- Convert URLs in Sync output UI into clickable links (#497)

### Fixed
- Changed prompts in configure from 0/1 to no/yes (#461)
- Added warnings when user is using incompatible git version (#488)
- Fixed the back button navigation between WebUI and Settings page (#361)
- Fixed issues with HL7 file extension inconsistencies (#495)
- Basic mode Sync operation now imports items changed on the remote merge branch (#506)
- Fetch diff output uses correct remote branch (#509)
- Properly handle more cases of truncated filenames from git pull (#511)
- Made git-source-control backwards compatible with IRIS 2021.1 (#513)
- Sync, pull properly handle more change edge cases for import (#517, #496)
- "Status" menu item actually includes branch when IRIS version allows (#472)

## [2.5.0] - 2024-09-24

### Added
- New UI for the basic mode Sync (#415)
- Allow changing namespaces and IPM package context from web UI (#280)
- Support for editing repo from filesystem perspective via web application (#464)
- Support for downloading a VSCode workspace file from web UI
- IncrementalLoad pull event handler will update the running production, if any (#473)

### Fixed
- Instance wide settings are placed in proper global (#444)
- Avoid delay/errors in loading interop JS when there is a URL prefix (e.g., instance name in multi-instance webserver configuration)
- Added proper JS escaping in sync output
- Added support to switch branch in basic mode from menu (#451)
- Pull event handler will not fail when change set includes unmapped files (#453)
- Pull event handler will attempt compile even if there are failures to load (#457)
- Improved logging in preview and when errors occur via WebSocket commands (#467)
- Fixed pull event handler handling of extremely long class names from diff (#467)
- Fixed Git web UI prompt to update file list when file selected/unselected (#478)
- Fixed folder settings in mappings to be saved and persist (#483)
- Preview on the pull.csp page now shows commits from the correct branch (#490)

## [2.4.1] - 2024-08-02

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
