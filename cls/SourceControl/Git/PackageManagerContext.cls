Class SourceControl.Git.PackageManagerContext Extends %ZPM.PackageManager.Core.Singleton
{

Property InternalName As %String;

Property IsInDefaultPackage As %Boolean [ InitialExpression = 0 ];

Property IsInGitEnabledPackage As %Boolean [ InitialExpression = 0 ];

Property Package As %ZPM.PackageManager.Developer.Module [ InitialExpression = {$$$NULLOREF} ];

Property ResourceReference As %ZPM.PackageManager.Developer.ResourceReference [ InitialExpression = {$$$NULLOREF} ];

Method InternalNameSet(InternalName As %String = "") As %Status
{
    if (InternalName '= i%InternalName) {
        set i%InternalName = InternalName
        set ..Package = ##class(%ZPM.PackageManager.Developer.Extension.Utils).FindHomeModule(InternalName,,.resourceReference)
        set ..ResourceReference = resourceReference
        set ..IsInGitEnabledPackage = $IsObject(..Package) && ##class(%Library.File).DirectoryExists(##class(%Library.File).NormalizeFilename(".git",..Package.Root))
        set ..IsInDefaultPackage = $IsObject(..Package) && (##class(%Library.File).NormalizeDirectory(..Package.Root) = ##class(%Library.File).NormalizeDirectory(##class(SourceControl.Git.Utils).TempFolder()))
    }
    quit $$$OK
}

ClassMethod ForInternalName(InternalName As %String = "") As SourceControl.Git.PackageManagerContext
{
    set instance = ..%Get()
    set instance.InternalName = InternalName
    quit instance
}

Method Dump()
{
    write !,"Package manager context: "
    write !?4,"InternalName: ",..InternalName
    write !?4,"Package: ",$Select($IsObject(..Package):..Package.Name,1:"<none>")
    write !?4,"Resource: ",$Select($IsObject(..ResourceReference):..ResourceReference.Name,1:"<none>")
    write !?4,"Default? ",$Select(..IsInDefaultPackage:"Yes",1:"No")
    write !?4,"Git-enabled? ",$Select(..IsInGitEnabledPackage:"Yes",1:"No"),!
}

}

