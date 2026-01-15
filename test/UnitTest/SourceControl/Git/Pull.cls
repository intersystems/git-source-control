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

}
