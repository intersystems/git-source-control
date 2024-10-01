Class UnitTest.SourceControl.Git.Settings Extends %UnitTest.TestCase
{

Property SourceControlGlobal [ MultiDimensional ];

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Method SampleSettingsJSON()
{
    return {
        "pullEventClass": "pull event class",
        "percentClassReplace": "x",
        "decomposeProductions": true,
        "Mappings": {
            "TUV": { 
                "*": {
                    "directory": "tuv/"
                },
                "UnitTest": {
                    "directory": "tuv2/",
                    "noFolders": true
                }
            },
            "XYZ": {
                "*": {
                    "directory": "xyz/"
                }
            }
        }
    }
}

Method TestJSONImportExport()
{
    set settingsDynObj = ..SampleSettingsJSON()
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.decomposeProductions = ""
    set settings.percentClassReplace = ""
    set settings.pullEventClass = ""
    do settings.ImportDynamicObject(settingsDynObj)
    do $$$AssertEquals(settings.decomposeProductions, 1)
    do $$$AssertEquals(settings.percentClassReplace, "x")
    do $$$AssertEquals(settings.pullEventClass, "pull event class")
    do $$$AssertEquals($get(settings.Mappings("TUV","*")),"tuv/")
    do $$$AssertEquals($get(settings.Mappings("TUV","UnitTest")),"tuv2/")
    do $$$AssertTrue($get(settings.Mappings("TUV","UnitTest","NoFolders")))
    do $$$AssertEquals($get(settings.Mappings("XYZ","*")),"xyz/")

    $$$ThrowOnError(settings.%Save())
    set document = ##class(%RoutineMgr).%OpenId(##class(SourceControl.Git.Settings.Document).#INTERNALNAME)
    set settingsDynObj = ##class(%DynamicObject).%FromJSON(document.Code)
    do $$$AssertEquals(settingsDynObj.decomposeProductions, 1)
    do $$$AssertEquals(settingsDynObj.percentClassReplace, "x")
    do $$$AssertEquals(settingsDynObj.pullEventClass, "pull event class")
    do $$$AssertEquals(settingsDynObj.Mappings."TUV"."*".directory,"tuv/")
    do $$$AssertEquals(settingsDynObj.Mappings."TUV"."UnitTest".directory,"tuv2/")
    do $$$AssertTrue(settingsDynObj.Mappings."TUV"."UnitTest".noFolders)
    do $$$AssertEquals(settingsDynObj.Mappings."XYZ"."*".directory,"xyz/")
}

Method TestSaveAndImportSettings()
{
    // save settings
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.Mappings("CLS","Foo") = "foo/"
    set settings.pullEventClass = "SourceControl.Git.PullEventHandler.Default"
    set settings.percentClassReplace = "_"
    set settings.decomposeProductions = 1
    $$$ThrowOnError(settings.SaveWithSourceControl())
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).AddToSourceControl("git-source-control.GSC"))
    // settings file should be in source control
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("git-source-control.GSC"))
    do $$$AssertEquals($replace(##class(SourceControl.Git.Utils).ExternalName("git-source-control.GSC"),"\","/"),"git-source-control.json")
    // commit settings
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).Commit("git-source-control.GSC"))
    // settings should be in the global
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","mappings","CLS","Foo"),"foo/")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","pullEventClass"),"SourceControl.Git.PullEventHandler.Default")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","percentClassReplace"),"_")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","decomposeProductions"),"1")
    // change and save settings
    set settings.Mappings("CLS","Foo") = "foo2/"
    set settings.pullEventClass = "SourceControl.Git.PullEventHandler.IncrementalLoad"
    set settings.percentClassReplace = "x"
    set settings.decomposeProductions = 0
    $$$ThrowOnError(settings.SaveWithSourceControl())
    // new setting should be in the global
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","mappings","CLS","Foo"),"foo2/")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","pullEventClass"),"SourceControl.Git.PullEventHandler.IncrementalLoad")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","percentClassReplace"),"x")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","decomposeProductions"),"0")
    // revert change to settings 
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).Revert("git-source-control.GSC"))
    // old setting should be in the global
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","mappings","CLS","Foo"),"foo/")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","pullEventClass"),"SourceControl.Git.PullEventHandler.Default")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","percentClassReplace"),"_")
    do $$$AssertEquals(^SYS("SourceControl","Git","settings","decomposeProductions"),"1")
}

Method OnBeforeAllTests() As %Status
{
	merge ..SourceControlGlobal = ^SYS("SourceControl")
    return $$$OK
}

Method OnBeforeOneTest() As %Status
{
	kill ^SYS("SourceControl")
	do ##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension")
    set settings = ##class(SourceControl.Git.Settings).%New()
	set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"dir"
    $$$ThrowOnError(settings.%Save())
    set workMgr = $System.WorkMgr.%New("")
    $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Utils).Init"))
    $$$ThrowOnError(workMgr.WaitForComplete())
	quit $$$OK
}

Method %OnClose() As %Status
{
	do ##class(%Studio.SourceControl.Interface).SourceControlClassSet(..InitialExtension)
	kill ^SYS("SourceControl")
	merge ^SYS("SourceControl") = ..SourceControlGlobal
	quit $$$OK
}

}
