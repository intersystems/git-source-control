Class SourceControl.Git.PullEventHandler.PackageManagerReload Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Package Manager Reload";

Parameter DESCRIPTION = "Does zpm ""uninstall"", then zpm ""load <repo root>""";

/// Subclasses may override to customize behavior on pull.
Method OnPull() As %Status
{
    set moduleFilePath = ##class(%File).NormalizeFilename("module.xml",..LocalRoot)
    set sc = $System.OBJ.Load(moduleFilePath,"-d",,.internalName,1) // list-only load to get module name
    $$$QuitOnError(sc)
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(internalName)
    if $isobject(context.Package) {
        set command = "uninstall "_context.Package.Name
        set sc = $select(
            $$$comClassDefined("%IPM.Main"): ##class(%IPM.Main).Shell(command),
            1: ##class(%ZPM.PackageManager).Shell(command)
        )
        $$$QuitOnError(sc)
    }
    set command = "load "_..LocalRoot
    quit $select(
        $$$comClassDefined("%IPM.Main"): ##class(%IPM.Main).Shell(command),
        1: ##class(%ZPM.PackageManager).Shell(command)
    )
}

}
