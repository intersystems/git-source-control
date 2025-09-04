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

## Push to remote branch (force)
This option forcibly pushes the commits in the branch to the remote repository. This is potentially destructive and may overwrite the commit history of the remote branch. This exhibits the same behavior as the [git push --force](https://git-scm.com/docs/git-push) command.

## Fetch from remote
This option first [fetches](https://git-scm.com/docs/git-fetch) the most recent version of the branch without merging that version into the local copy of the branch.  It will then list all files modified between the current version and the remote version.

This also has the effect of refreshing the list of all remote branches and pruning any references that no longer exist in the remote.  (see: [git fetch --prune](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune))

## Pull changes from remote branch
Much like the [git pull](https://git-scm.com/docs/git-pull) command, this menu option pulls the most recent version of the current branch from a remote source, merging the changes into the local copy.

## Sync
This option will synchronize the current branch checked out a local repo with the same branch in a remote repo.  It encapsulates the pattern of fetching, pulling, committing, and pushing into one menu action.
- If you are on the Default Merge Branch, then Sync only pulls the latest commits from the remote.  Committing is disallowed on the Default Merge Branch.
- If there is no defined remote repository, it will simply commit any uncommitted files.
- If there is a Default Merge Branch defined, then sync attempts to perform a rebase onto the latest Default Merge Branch from the remote.
    - If the rebase were to result in merge conflicts, then this action is aborted so the system is not left in an inconsistent state.


The sync operation is only enabled in basic mode.

## Create new branch
This menu option creates a new branch in the repository for changes to be committed to. It also changes the current branch to be the created branch. This mimics the behavior of the [git checkout -b](https://git-scm.com/docs/git-checkout) command.

In basic mode, this option first checks out the Default Merge Branch (if defined) and pulls that branch from the remote before creating the new branch.

## Check out an existing branch
This option refreshes the local list of branches available in the upstream repository, and then changes the currently checked out branch to the provided branch.  This mimics the behavior of the [git fetch --prune](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune) and [git checkout](https://git-scm.com/docs/git-checkout) commands.

If the desired branch does not exist in your local or in the remote, then you will receive the "Selected branch does not exist" error message.

## Export all
This option exports class files to the local file tree at the configured location.

## Export all (force)
This option exports all class files regardless of whether they're already up to date in the local file tree or not.

## Import all
This option imports the versions of the files that are found in the configured directory into the project. Files that are out of date or the same as the files in the project won't be imported.

## Import all (force)
This menu option behaves similarly to the regular import but forces the files to be imported regardless of whether the on-disk version is the same or older.
