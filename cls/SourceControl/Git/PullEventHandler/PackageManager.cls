Class SourceControl.Git.PullEventHandler.PackageManager Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Package Manager";

Parameter DESCRIPTION = "Does zpm ""load <repo root>""";

/// Subclasses may override to customize behavior on pull.
Method OnPull() As %Status
{
    set command = "load "_..LocalRoot
    set key = $order(@##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags",""))
    while (key '= "") {
        set command = command _ " -" _ $zstrip(key,"*W") _ "=" _ $zstrip(@##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags",key),"*W")
        set key = $order(@##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags",key))
    }
    quit $select(
        $$$comClassDefined("%IPM.Main"): ##class(%IPM.Main).Shell(command),
        1: ##class(%ZPM.PackageManager).Shell(command)
    )
}

/// Configures additional flags to be used with zpm "load" by Package Manager pull event handlers
/// Example: to use `zpm "load -DNoMapping=1"` run the following:
/// ```
/// kill flags set flags("DNoMapping") = 1
/// do ##class(SourceControl.Git.PullEventHandler.PackageManager).ConfigureLoadFlags(.flags)
/// ```
ClassMethod ConfigureLoadFlags(ByRef flags)
{
    kill @##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags")
    set key = $order(flags(""))
    while (key '= "") {
        set @##class(SourceControl.Git.Utils).#Storage@("settings","IPM","loadFlags",key) = flags(key)
        set key = $order(flags(key))
    }
}

}
