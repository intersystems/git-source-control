/// Integration tests that cover deployment of changes into IRIS with git pull
Class UnitTest.SourceControl.Git.Pull Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestPull()
{
    // initialize remote repository on filesystem
    set remoteDir = ##class(%Library.File).TempFilename()_"d"
    if '##class(%File).CreateDirectoryChain(remoteDir_"/cls",.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to create directory: "_ret))
    }
    do ..WriteFile(remoteDir_"/cls/TestGit/SampleClass1.cls","Class TestGit.SampleClass1 {}")
    do ..WriteFile(remoteDir_"/cls/TestGit/SampleClass2.cls","Class TestGit.SampleClass2 {}")
    do $zf(-100,"/SHELL","git","init",remoteDir)
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.email", "unittest@example.com")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.name", "Unit Test")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "initial commit in remote for unit test")
    // initialize local repo, cloning remote.
    do ..ResetLocalRepo()
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Clone(remoteDir_"/.git"))
    // import all and confirm classes exist
    do $System.OBJ.Delete("TestGit.SampleClass1,TestGit.SampleClass2")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).ImportAll(1))
    do $$$AssertTrue($$$comClassDefined("TestGit.SampleClass1"))
    do $$$AssertTrue($$$comClassDefined("TestGit.SampleClass2"))
    // delete, add, and modify classes on remote. add and commit them all on remote.
    if '##class(%File).Delete(remoteDir_"/cls/TestGit/SampleClass1.cls",.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to delete class file"))
    }
    do ..WriteFile(remoteDir_"/cls/TestGit/SampleClass2.cls","Class TestGit.SampleClass2 { Parameter foo = ""bar""; }")
    do ..WriteFile(remoteDir_"/cls/TestGit/SampleClass3.cls","Class TestGit.SampleClass3 {}")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "delete, modify, and add classes on remote")
    // pull on local and confirm changes were loaded.
    $$$ThrowOnError(##class(SourceControl.Git.API).Pull())
    do $$$AssertNotTrue($$$comClassDefined("TestGit.SampleClass1"))
    do $$$AssertEquals(##class(TestGit.SampleClass2).#foo, "bar")
    do $$$AssertTrue($$$comClassDefined("TestGit.SampleClass3"))
}

Method TestPullWithConfigChange()
{
    // initialize remote repository on filesystem
    set remoteDir = ##class(%Library.File).TempFilename()_"d"
    if '##class(%File).CreateDirectoryChain(remoteDir_"/data/lut",.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to create directory: "_ret))
    }
    do ..WriteFile(remoteDir_"/embedded-git-config.json",{
        "pullEventClass":"SourceControl.Git.PullEventHandler.Default"
        }.%ToJSON())
    do $zf(-100,"/SHELL","git","init",remoteDir)
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.email", "unittest@example.com")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.name", "Unit Test")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "initial commit in remote for unit test")
    // initialize local repo, cloning remote.
    do ..ResetLocalRepo()
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Clone(remoteDir_"/.git"))
    // make sure LUT does not exist to begin with
    do ##class(%RoutineMgr).Delete("embedded-git-unit-test.lut")
    // on remote, add a mapping for LUT and create a lookup-table.
    do ..WriteFile(remoteDir_"/embedded-git-config.json",{
        "pullEventClass":"SourceControl.Git.PullEventHandler.Default",
        "Mappings": {
            "LUT": {
                "*": {
                    "directory": "data/lut/",
                    "noFolders": true
                }
            }
        }
    }.%ToJSON())
    do ..WriteFile(remoteDir_"/data/lut/embedded-git-unit-test.lut",
        ..SampleLUTFileContents())
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "add a mapping for LUT and a LUT at the same time")
    // pull on local and confirm mapping exists and LUT was loaded
    $$$ThrowOnError(##class(SourceControl.Git.API).Pull())
    do $$$AssertTrue(##class(%RoutineMgr).Exists("embedded-git-unit-test.lut"))
    do $$$AssertEquals($get(^SYS("SourceControl","Git","settings","mappings","LUT","*")), "data/lut/")
    do ##class(%RoutineMgr).Delete("embedded-git-unit-test.lut")
}

Method TestPullWithRename()
{
    // initialize remote repository on filesystem
    set remoteDir = ##class(%Library.File).TempFilename()_"d"
    if '##class(%File).CreateDirectoryChain(remoteDir_"/cls",.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to create directory: "_ret))
    }
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.Mappings("LUT","*") = "data/lut/"
    set settings.Mappings("LUT","*","NoFolders") = 1
    do settings.%Save()
    do ..WriteFile(remoteDir_"/data/lut/embedded-git-unit-test.lut", ..SampleLUTFileContents())
    do $zf(-100,"/SHELL","git","init",remoteDir)
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.email", "unittest@example.com")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.name", "Unit Test")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "initial commit in remote for unit test")
    // initialize local repo, cloning remote.
    do ..ResetLocalRepo()
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Clone(remoteDir_"/.git"))
    // import all and confirm LUT exists
    $$$ThrowOnError(##class(SourceControl.Git.Utils).ImportAll(1))
    do $$$AssertTrue(##class(%RoutineMgr).Exists("embedded-git-unit-test.lut"))
    // rename the LUT on the remote
    if '##class(%File).Rename(remoteDir_"/data/lut/embedded-git-unit-test.lut",remoteDir_"/data/lut/embedded-git-unit-test-2.lut",.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to rename LUT file: "_ret))
    }
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "delete, modify, and add classes on remote")
    // pull on local and confirm LUT was updated
    $$$ThrowOnError(##class(SourceControl.Git.API).Pull())
    do $$$AssertNotTrue(##class(%RoutineMgr).Exists("embedded-git-unit-test.lut"))
    do $$$AssertTrue(##class(%RoutineMgr).Exists("embedded-git-unit-test-2.lut"))
}

ClassMethod SampleLUTFileContents() As %String
{
    return "<?xml version=""1.0""?>"_$c(13,10)_ 
        "<lookupTable>"_$c(13,10)_ 
        "<entry table=""pbarton"" key=""foo"">bar</entry>"_$c(13,10)_ 
        "</lookupTable>"
}

}
