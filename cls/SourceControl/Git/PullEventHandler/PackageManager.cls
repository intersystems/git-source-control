Class SourceControl.Git.PullEventHandler.PackageManager Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Package Manager";

Parameter DESCRIPTION = "Does zpm ""load <repo root>""";

/// Subclasses may override to customize behavior on pull.
Method OnPull() As %Status
{
    set command = "load "_..LocalRoot
    quit $select(
        $$$comClassDefined("%IPM.Main"): ##class(%IPM.Main).Shell(command),
        1: ##class(%ZPM.PackageManager).Shell(command)
    )
}

}
