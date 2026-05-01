Class UnitTest.SourceControl.Git.Utils.NewBranch Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestCreateSupportedBranchNames()
{
    $$$ThrowOnError(##class(SourceControl.Git.Utils).Init())
    do $$$AssertStatusNotOK(##class(SourceControl.Git.Utils).NewBranch("not a good#branch name"))
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).NewBranch("a-good/branch-name.2"))
}

}
