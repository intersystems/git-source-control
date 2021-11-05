Include SourceControl.Git

Class SourceControl.Git.PullEventHandler.Default Extends (SourceControl.Git.PullEventHandler.IncrementalLoad, SourceControl.Git.PullEventHandler.PackageManager)
{

Parameter NAME = "Default";

Parameter DESCRIPTION = "Does a zpm ""load <repo root>"" for PackageManager-enabled repos and an incremental load otherwise.";

Method OnPull() As %Status
{
    if ##class(%Library.File).Exists(##class(%Library.File).NormalizeFilename("module.xml",..LocalRoot)) {
        quit ##class(SourceControl.Git.PullEventHandler.PackageManager)$this.OnPull()
    }
    quit ##class(SourceControl.Git.PullEventHandler.IncrementalLoad)$this.OnPull()
}

}

