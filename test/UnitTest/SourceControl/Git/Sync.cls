Class UnitTest.SourceControl.Git.Sync Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestSync()
{
    do $$$LogMessage("set up remote repo on filesystem")
    set remoteDir = ##class(%Library.File).TempFilename()_"d"
    if '##class(%File).CreateDirectoryChain(remoteDir,.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to create directory: "_ret))
    }
    do $zf(-100,"/SHELL","git","init",remoteDir)
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.email", "unittest@example.com")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "config", "user.name", "Unit Test")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "checkout", "-b", "live")
    do ..WriteFile(remoteDir_"/cls/TestGit/SampleClass1.cls","Class TestGit.SampleClass1 {}")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "initial commit in remote for unit test")
    do $$$LogMessage("initialize local repo cloning remote")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Clone(remoteDir_"/.git"))
    do $$$LogMessage("set default merge branch to live and enable basic mode")
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.defaultMergeBranch = "live"
    set settings.basicMode = "system"
    set settings.systemBasicMode = 1
    $$$ThrowOnError(settings.%Save())
    do $$$LogMessage("check out live branch on local")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).SwitchBranch("live"))
    do $$$LogMessage("create a class through IRIS, add it to source control, and sync")
    do $System.OBJ.Delete("TestGit.SampleClass2")
    set classDef = ##class(%Dictionary.ClassDefinition).%New("TestGit.SampleClass2")
    $$$ThrowOnError(classDef.%Save())
    $$$ThrowOnError($System.OBJ.Compile("TestGit.SampleClass2"))
    $$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl("TestGit.SampleClass2.cls"))
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Sync("should not commit"))
    do $$$LogMessage("sync should NOT have committed the new file since we are on the live branch.")
    do $$$AssertTrue(##class(SourceControl.Git.Change).IsUncommitted(##class(SourceControl.Git.Utils).FullExternalName("TestGit.SampleClass2.cls")))
    do $$$LogMessage("now, check out an interface branch")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).NewBranch("interface"))
    do $$$LogMessage("simulate another developer's change going live")
    do ..WriteFile(remoteDir_"/cls/TestGit/SampleClass1.cls","Class TestGit.SampleClass1 { Parameter foo = ""bar""; }")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "add", ".")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "commit", "-m", "initial commit in remote for unit test")
    do $$$LogMessage("check out an interface branch and sync")
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Sync("should commit"))
    do $$$LogMessage("sync should have rebased the other developer's change, and committed the new file.")
    do $$$AssertEquals(##class(TestGit.SampleClass1).#foo, "bar")
    do $$$AssertNotTrue(##class(SourceControl.Git.Change).IsUncommitted(##class(SourceControl.Git.Utils).FullExternalName("TestGit.SampleClass2.cls")))
    do $$$LogMessage("simulate a merge request on the remote from the interface branch to live.")
    do $zf(-100,"/SHELL","git", "-C", remoteDir, "merge", "interface")
    do $$$AssertTrue(##class(%File).Exists(remoteDir_"/cls/TestGit/SampleClass2.cls"))
}

}
