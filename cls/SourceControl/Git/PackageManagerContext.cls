Class SourceControl.Git.PackageManagerContext Extends SourceControl.Git.Util.Singleton
{

Property InternalName As %String;

Property IsInDefaultPackage As %Boolean [ InitialExpression = 0 ];

Property IsInGitEnabledPackage As %Boolean [ InitialExpression = 0 ];

/// Really is a %ZPM.PackageManager.Developer.Module / %IPM.Storage.Module
Property Package As %RegisteredObject [ InitialExpression = {$$$NULLOREF} ];

/// Really is a %ZPM.PackageManager.Developer.ResourceReference / %IPM.Storage.ResourceReference
Property ResourceReference As %RegisteredObject [ InitialExpression = {$$$NULLOREF} ];

Method InternalNameSet(InternalName As %String = "") As %Status
{
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    if (InternalName '= i%InternalName) {
        set i%InternalName = InternalName
        if $$$comClassDefined("%IPM.ExtensionBase.Utils") {
            set ..Package = ##class(%IPM.ExtensionBase.Utils).FindHomeModule(InternalName,,.resourceReference)
        } elseif $$$comClassDefined("%ZPM.PackageManager.Developer.Extension.Utils") {
            set ..Package = ##class(%ZPM.PackageManager.Developer.Extension.Utils).FindHomeModule(InternalName,,.resourceReference)
        } else {
            quit $$$OK
        }
        set ..ResourceReference = resourceReference
        set ..IsInGitEnabledPackage = $isobject(..Package) && ##class(%Library.File).Exists(##class(%Library.File).NormalizeFilename(".git",..Package.Root))
        set ..IsInDefaultPackage = $isobject(..Package) && (##class(%Library.File).NormalizeDirectory(..Package.Root) = ##class(%Library.File).NormalizeDirectory(##class(SourceControl.Git.Utils).DefaultTempFolder()))
    }
    quit $$$OK
}

ClassMethod ForInternalName(InternalName As %String = "") As SourceControl.Git.PackageManagerContext
{
    set instance = ..%Get()
    set instance.InternalName = InternalName
    set InternalName = instance.InternalName
    quit instance
}

Method Dump()
{
    write !,"Package manager context: "
    write !?4,"InternalName: ",..InternalName
    write !?4,"Package: ",$select($isobject(..Package):..Package.Name,1:"<none>")
    write !?4,"Resource: ",$select($isobject(..ResourceReference):..ResourceReference.Name,1:"<none>")
    write !?4,"Default? ",$select(..IsInDefaultPackage:"Yes",1:"No")
    write !?4,"Git-enabled? ",$select(..IsInGitEnabledPackage:"Yes",1:"No"),!
}

}
