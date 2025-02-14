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
        set sc = ##class(%ZPM.PackageManager).Shell("uninstall "_context.Package.Name)
        $$$QuitOnError(sc)
    }
    quit ##class(%ZPM.PackageManager).Shell("load "_..LocalRoot)
}

}
