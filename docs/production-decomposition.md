# Production Decomposition
Production Decomposition is a feature of Embedded Git that allows multiple developers to edit the same IRIS Interoperability production in the same namespace. In the past, the production class has been an obstacle preventing organizations using multi-user development namespaces from adopting source control. Production Decomposition resolves this by representing the production as a directory of files for each production item that may be edited independently. An uncommitted change to the settings for a single item through the Interoperability Portal will block other users from editing that item while allowing changes to other items in the production.

## Enabling production decomposition
The feature may be enabled by checking the "Decompose Productions" box in the Git Settings page. For deployment of changes to other environments through git to work properly, the value of this setting must match on all namespaces connected to this repository. To assist, settings are automatically exported into a `embedded-git-config.json` file at the root of the repository that may be committed and imported into other environments.

If there are existing productions in the namespace, they should be migrated to the new decomposed format by running `do ##class(SourceControl.Git.API).BaselineProductions()`. You may then use the Git Web UI to view, commit, and push the corresponding changes. This method should be run in a single namespace and then deployed to other namespaces through normal Embedded Git deployment mechanisms.

## Editing productions in the IDE
There are a couple of limitations related to editing a production class directly in an integrated development environment (Studio or VS Code).
- Any elements of the class definition other than the production definition (for example, methods, parameters, or a custom superclass) are not source controlled if production decomposition is enabled. A recommended workaround is to move these items to a separate utility class.
- The hooks in the IDE are not able to detect which specific production items are being edited. As a result, if any item has an uncommitted change from a different user, you will be blocked from editing the production in the IDE entirely.
As a result of these limitations, editing decomposed productions in the IDE is prohibited by default. To enable it, enable the "Decomposed Productions Allow IDE" setting on the settings page.

## Known Limitations
- Any custom methods, parameters, etc. in the production class will not be source controlled if Production Decomposition is enabled. A recommended workaround is to move these items to a separate utility class.
- Production Decomposition is not supported for deployment of changes to productions using the InterSystems Package Manager.
