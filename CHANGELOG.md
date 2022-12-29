# git-source-control

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.6] - Unreleased

### Added
- Support for Caché/Ensemble 2016.2.3, 2017.1.2, 2017.2.1, 2018.1.0 and later. (Treated as patch version bump because no compatibility impact for existing users.)

### Fixed
- "Import All" will properly recognize new files
- "Import All" and "Export All" apply only to the current package manager context and disregard items outside that context

### Changed
- Various minor things under the hood to support use without the package manager and/or on older platforms

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

