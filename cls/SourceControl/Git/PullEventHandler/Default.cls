Include SourceControl.Git

Class SourceControl.Git.PullEventHandler.Default Extends (SourceControl.Git.PullEventHandler.IncrementalLoad, SourceControl.Git.PullEventHandler.PackageManager)
{

Parameter NAME = "Default";

Parameter DESCRIPTION = "Does a zpm ""load <repo root>"" for PackageManager-enabled repos and an incremental load otherwise.";

Method OnPull() As %Status
{
    If ##class(%Library.File).Exists(##class(%Library.File).NormalizeFilename("module.xml",..LocalRoot)) {
        Quit ##class(SourceControl.Git.PullEventHandler.PackageManager)$This.OnPull()
    }
    Quit ##class(SourceControl.Git.PullEventHandler.IncrementalLoad)$This.OnPull()
}

}

