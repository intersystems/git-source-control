# git-source-control

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.1] - Unreleased

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

