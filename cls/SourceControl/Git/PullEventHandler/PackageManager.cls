Class SourceControl.Git.PullEventHandler.PackageManager Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Package Manager";

Parameter DESCRIPTION = "Does zpm ""load <repo root>""";

/// Subclasses may override to customize behavior on pull.
Method OnPull() As %Status
{
    set command = "load "_..LocalRoot
    set additionalFlags = ..GetLoadFlags()
    if (additionalFlags'="") set command = command _ " " _ additionalFlags
    quit $select(
        $$$comClassDefined("%IPM.Main"): ##class(%IPM.Main).Shell(command),
        1: ##class(%ZPM.PackageManager).Shell(command)
    )
}

/// Configures additional flags to be used with zpm "load" by Package Manager pull event handlers
/// Example: to use `zpm "load -DNoMapping=1"` run the following:
/// ```
/// do ##class(SourceControl.Git.PullEventHandler.PackageManager).ConfigureLoadFlags("-DNoMapping=1")
/// ```
ClassMethod ConfigureLoadFlags(flags = "")
{
    set @##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags") = flags
}

ClassMethod GetLoadFlags() As %String
{
    return $get(@##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags"))
}

}
