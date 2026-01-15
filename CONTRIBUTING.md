# How to Contribute

Thank you for your interest in contributing! While this project originated at InterSystems, it is our hope that the community will continue to extend and enhance it.

## Getting Started

We recommend setting up a local development instance by following these steps:
1. Install an instance of IRIS (go to https://evaluation.intersystems.com/ for an evaluation kit).
2. Install IPM (InterSystems Package Manager) (https://github.com/intersystems/ipm).
3. Clone a copy of the Embedded Git repository to disk using `git clone`.
4. Install Embedded Git using IPM by running this terminal command (`zpm "load <path_to_embedded_git_repo_directory> -dev"`).
5. Configure your Embedded Git instance to point at a Git repository that IS NOT Embedded Git (it can get very messy very quickly).
6. Modify the code locally! Note that any changes to CSP pages will require loading the module again with IPM to propagate the changes to your local instance.

## Submitting changes

If you have made a change that you would like to contribute back to the community, please send a [GitHub Pull Request](/pull/new/main) explaining it. If your change fixes an issue that you or another user reported, please mention it in the pull request. You can find out more about pull requests [here](http://help.github.com/pull-requests/).

Every pull request should include at least one entry in CHANGELOG.md - see [keepachangelog.com](https://keepachangelog.com/) for guidelines.

We encourage use of [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Coding Conventions

Generally speaking, just try to match the conventions you see in the code you are reading. For this project, these include:

* Use the full command and function names. For example, use `set` instead of `s` and `$piece` instead of `$p`
* One command per line
* Indentation with tabs
* [Pascal case](https://en.wikipedia.org/wiki/Camel_case) class and method names
* Avoid dot syntax
* Avoid postconditionals
* Always check %Status return values

When making changes that involve JavaScript, ensure that your changes still work from Studio (which uses an old version of IE under the hood and therefore doesn't support various things you might take for granted).

Thank you!