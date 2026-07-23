Class UnitTest.SourceControl.Git.Utils.GitLaunchError Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Triggers a real <NOTOPEN> by launching a nonexistent executable, passes the caught
/// exception through GitLaunchError, and verifies the message reports the actual OS
/// error (ENOENT) plus the "not found" hint, with no docs link.
Method TestTranslatesNotOpenForMissingBinary()
{
    set outLog = ##class(%Library.File).TempFilename()
    set errLog = ##class(%Library.File).TempFilename()
    set baseArgs = "/STDOUT="_""""_outLog_""""_" /STDERR="_""""_errLog_""""
    set translated = ""
    try {
        set rc = $zf(-100, baseArgs, "/nonexistent/path/to/git-binary-xyz", "--version")
    } catch e {
        set translated = ##class(SourceControl.Git.Utils).GitLaunchError(e)
    }
    do ##class(%File).Delete(outLog)
    do ##class(%File).Delete(errLog)

    do $$$AssertTrue($isobject(translated), "a <NOTOPEN> was raised and translated")
    if '$isobject(translated) {
        quit
    }
    set msg = translated.DisplayString()
    do $$$AssertEquals(translated.Name, "<NOTOPEN>", "translated exception keeps the <NOTOPEN> name")
    do $$$AssertTrue(msg [ "git could not be launched", "message explains git launch failed")
    do $$$AssertTrue(msg [ "git was not found", "errno 2 maps to the not-found hint")
    // The OS error text is embedded; on POSIX this is "No such file or directory".
    do $$$AssertTrue(msg [ "No such file or directory", "message includes the underlying OS error text")
    do $$$AssertTrue('(msg [ "http"), "runtime message contains no docs link")
}

/// A <NOTOPEN> whose OS error code is neither ENOENT nor EACCES falls back to the
/// generic hint. OSError() is a lingering value, so this is verified indirectly: any
/// <NOTOPEN> translation must still produce an actionable, link-free message.
Method TestTranslatesNotOpenIsActionable()
{
    set src = ##class(%Exception.General).%New("<NOTOPEN>", "", "", "")
    set translated = ##class(SourceControl.Git.Utils).GitLaunchError(src)
    set msg = translated.DisplayString()
    do $$$AssertEquals(translated.Name, "<NOTOPEN>", "translated exception keeps the <NOTOPEN> name")
    do $$$AssertTrue(msg [ "git could not be launched", "message explains git launch failed")
    do $$$AssertTrue(msg [ "git", "message references git and how to fix it")
    do $$$AssertTrue('(msg [ "http"), "runtime message contains no docs link")
}

Method TestPassesThroughOtherErrors()
{
    set src = ##class(%Exception.General).%New("<UNDEFINED>", "", "", "")
    set src.Name = "<UNDEFINED>"
    set translated = ##class(SourceControl.Git.Utils).GitLaunchError(src)
    do $$$AssertEquals(translated.Name, "<UNDEFINED>", "non-NOTOPEN error passes through unchanged")
}

/// On Linux, a launch failure inside the /SHELL retry does NOT throw <NOTOPEN> -- it
/// returns shell exit code 127 (command not found). RunGitCommand must still raise an
/// actionable error rather than silently returning 127.
Method TestRunGitCommandThrowsForMissingConfiguredPath()
{
    set storage = ##class(SourceControl.Git.Utils).%SYSNamespaceStorage()
    set saved = $get(@storage@("%gitBinPath"))
    set threw = 0
    try {
        set @storage@("%gitBinPath") = "/nonexistent/path/to/git-binary-xyz"
        kill ^||GitVersion
        try {
            do ##class(SourceControl.Git.Utils).RunGitCommand("status", .err, .out)
        } catch e {
            set threw = 1
            do $$$AssertEquals(e.Name, "<NOTOPEN>", "missing configured git path raises <NOTOPEN>")
            set msg = e.DisplayString()
            do $$$AssertTrue(msg [ "git was not found", "message identifies the missing git executable")
        }
        do $$$AssertTrue(threw, "RunGitCommand raised an error instead of returning a bare shell exit code")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    if (saved = "") {
        kill @storage@("%gitBinPath")
    } else {
        set @storage@("%gitBinPath") = saved
    }
    kill ^||GitVersion
}

/// Same shell-retry gap, for a configured path that exists but is not executable
/// (shell exit 126).
Method TestRunGitCommandThrowsForNonExecutableConfiguredPath()
{
    set fake = "/tmp/eg-test-fakegit-"_$job
    set stream = ##class(%Stream.FileCharacter).%New()
    set stream.Filename = fake
    do stream.Write("#!/bin/sh"_$c(10))
    do stream.%Save()
    do $zf(-100, "/SHELL", "chmod", "600", fake)

    set storage = ##class(SourceControl.Git.Utils).%SYSNamespaceStorage()
    set saved = $get(@storage@("%gitBinPath"))
    set threw = 0
    try {
        set @storage@("%gitBinPath") = fake
        kill ^||GitVersion
        try {
            do ##class(SourceControl.Git.Utils).RunGitCommand("status", .err, .out)
        } catch e {
            set threw = 1
            do $$$AssertEquals(e.Name, "<NOTOPEN>", "non-executable configured git path raises <NOTOPEN>")
            set msg = e.DisplayString()
            do $$$AssertTrue(msg [ "git could not be executed", "message identifies the non-executable git path")
        }
        do $$$AssertTrue(threw, "RunGitCommand raised an error instead of returning a bare shell exit code")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    if (saved = "") {
        kill @storage@("%gitBinPath")
    } else {
        set @storage@("%gitBinPath") = saved
    }
    kill ^||GitVersion
    do ##class(%File).Delete(fake)
}

}
