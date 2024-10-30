# Baselining Source Code
Baselining source code is the first step to enabling source control on an existing system. Baselining synchronizes the Git repository with a source of truth, usually the current state of the production environment. This establishes a clean starting point so that any future changes can be tracked.

Git-source-control includes an API method `BaselineExport` that may be run in an IRIS terminal to export items in a namespace to the configured Git repository. 

A baselining workflow will commonly include these steps:
- Create a new remote repository on your Git platform of choice.
- Use `do ##class(SourceControl.Git.API).Configure()` to configure Git on the production environment (or a copy of the production environment). Clone the new remote repository.
- Use the Settings page in the Source Control menu to customize the mapping configuration.
- Use the Source Control menu to check out a new branch for the baseline export.
- Use the `BaselineExport` method to export all items to the Git repository, commit, and push to the remote: `do ##class(SourceControl.Git.API).BaselineExport("initial baseline commit","origin")`
- Create a merge or pull request on your remote Git platform from the baseline branch to the main branch. Review the code to ensure it includes all required items. If needed, modify the mapping configuration and redo the baseline export. When the baseline is satisfactory, merge it into the main branch.
- Use the Source Control menu to switch back to the main branch on the production environment.
- For each other environment, configure Git to clone that same remote repository. From the Source Control menu, run Import All (Force) to load all items from the baseline.