# How to contribute

Thank you for your interest in contributing! While this project originated at InterSystems, it is our hope that the community will continue to extend and enhance it.

## Submitting changes

If you have made a change that you would like to contribute back to the community, please send a [GitHub Pull Request](/pull/new/master) explaining it. If your change fixes an issue that you or another user reported, please mention it in the pull request. You can find out more about pull requests [here](http://help.github.com/pull-requests/).

Every pull request should include at least one entry in CHANGELOG.md - see [keepachangelog.com](https://keepachangelog.com/) for guidelines.

We encourage use of [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## Coding conventions

Generally speaking, just try to match the conventions you see in the code you are reading. For this project, these include:

* Do not use shortened command and function names - e.g., `s` instead of `set`, `$p` instead of `$piece`
* One command per line
* Do not use dot syntax
* Indentation with tabs
* Pascal case class and method names
* Avoid using postconditionals
* Local variables start with `t`; formal parameter names start with `p`
* Always check %Status return values

When making changes that involve JavaScript, ensure that your changes still work from Studio (which uses an old version of IE under the hood and therefore doesn't support various things you might take for granted).

Thank you!