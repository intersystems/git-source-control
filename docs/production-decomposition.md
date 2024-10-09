# Production Decomposition
Production Decomposition is a feature of git-source-control that allows multiple developers to edit the same IRIS Interoperability production in the same namespace. In the past, the production class has been an obstacle preventing organizations using multi-user development namespaces from adopting source control. Production Decomposition resolves this by representing the production as a directory of files for each production item that may be edited independently. An uncommitted change to the settings for a single item through the Interoperability Portal will block other users from editing that item while allowing changes to other items in the production.

## Enabling production decomposition
The feature may be enabled by checking the "Decompose Productions" box in the Git Settings page. For deployment of changes to other environments through git to work properly, the value of this setting must match on all namespaces connected to this repository. To assist, settings are automatically exported into a `git-source-control.json` file at the root of the repository that may be committed and imported into other environments.

If there are existing productions in the namespace, they should be migrated to the new decomposed format by running `do ##class(SourceControl.Git.API).BaselineProductions()`. You may then use the Git Web UI to view, commit, and push the corresponding changes. This method should be run in a single namespace and then deployed to other namespaces through normal git-source-control deployment mechanisms.

## Known Limitations
- The source control hooks for Production Decomposition are currently only supported when editing via the Interoperability Portal. Editing the production class directly in VS Code or Studio may overwrite other users' changes.
- Any custom methods, parameters, etc. in the production class will not be source controlled if Production Decomposition is enabled. A recommended workaround is to move these items to a separate utility class.
- Production Decomposition is not supported for deployment of changes to productions using the InterSystems Package Manager.
