# Test File

This is an unrelated tracked file used to make changes to test commits. 

### Test 1

Created this file. Updated `RunGitCommanWithInput()` to pass user information using the `-c` flag at every git call. 

### Test 2

Deleted global user settings from `.gitconfig`

### Test 3

Properly update project settings.

### Test 4

Set global user settings again. 

## Results

1. Every git command is now run with the user configured in the project settings i.e. it is based on `$username`.
2. This supercedes any global or repository level user setting. 