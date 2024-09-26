Class SourceControl.Git.PullEventHandler.PackageManager Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Package Manager";

Parameter DESCRIPTION = "Does zpm ""load <repo root>""";

/// Subclasses may override to customize behavior on pull.
Method OnPull() As %Status
{
    quit ##class(%ZPM.PackageManager).Shell("load "_..LocalRoot)
}

}