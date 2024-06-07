# git-source-control Menu Items


## Status
This menu option is analogous to the [git status](https://git-scm.com/docs/git-status) command and prints the status of the repository to the output.
## Settings
This option opens the GUI's settings page project specific git-source-control settings can be configured. This includes the settings that were configured when running:
```
d ##class(SourceControl.Git.API).Configure()
```

This page also includes the mappings configurations.

Any changes made to the settings must be saved using the 'Save' button in order to take effect.
## Launch Git UI
This menu option opens the git-source-control GUI. From here commit messages can be written, files can be staged and committed, branches can be viewed.
## Add
This menu option is analogous to the [git add](https://git-scm.com/docs/git-add) command. It will perform 'git add' on the currently open file, adding it to the files that can be staged.
## Remove
This menu option will only appear if the currently open file has been already added using the 'Add' menu option. It undoes the effect of adding the file, similar to running [git reset](https://git-scm.com/docs/git-reset) on a specific file.
## Push to remote branch
This option pushes the commits in the branch to the remote repository. This exhibits the same behavior as the [git push](https://git-scm.com/docs/git-push) command.
## Fetch from remote
Much like the [git fetch](https://git-scm.com/docs/git-fetch) command, this option fetches the most recent versions of the branch without merging that version into the local copy of the branch.
## Pull changes from remote branch
Much like the [git pull](https://git-scm.com/docs/git-pull) command, this menu option pulls the most recent version of the current branch from a remote source, merging the changes into the local copy.
## Sync
This option will synchronize a local repo with the remote repo. The sync operation is only enabled in basic mode. It encapsulates the pattern of fetching, pulling, committing and then pushing into one menu action. If there is no defined remote repository, it will simply commit any uncommitted files.
## Create new branch
This menu option creates a new branch in the repository for changes to be committed to. It also changes the current branch to be the created branch. This mimics the behavior of the [git checkout -b](https://git-scm.com/docs/git-checkout) command.
## Check out an existing branch
This option changes the currently checkout branch to a chosen branch. This mimics the behavior of the [git checkout](https://git-scm.com/docs/git-checkout) command.
## Export all
This option exports class files to the local file tree at the configured location.
## Export all (force)
This option exports all class files regardless of whether they're already up to date in the local file tree or not.
## Import all
This option imports the versions of the files that are found in the configured directory into the project. Files that are out of date or the same as the files in the project won't be imported.
## Import all (force)
This menu option behaves similarly to the regular import but forces the files to be imported regardless of whether the on-disk version is the same or older. 
