Import SourceControl.Git

Include SourceControl.Git

Class UnitTest.SourceControl.Git.NameToInternalNameTest Extends %UnitTest.TestCase
{

Property Mappings [ MultiDimensional ];

Property OldNamespaceTemp As %String;

Method TestRegularClassNames()
{
	// Regular class that exists
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\SourceControl\Git\Utils.cls"),"SourceControl.Git.Utils.CLS")
	// Regular class that doesn't exist and we ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\SourceControl\Git\DoesNotExist.cls"),"")
	// Regular class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\SourceControl\Git\DoesNotExist.cls", 1, 0),"SourceControl.Git.DoesNotExist.CLS")
}

Method TestPercentClassNames()
{
	// % class that exists but we ignore % classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\Base.cls"),"")
	// % class that exists and we don't ignore % classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\Base.cls", 0),"%Studio.Extension.Base.CLS")
	// % class that doesn't exist and we ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\DoesNotExist.cls", 0),"")
	// % class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\DoesNotExist.cls", 0, 0),"%Studio.Extension.DoesNotExist.CLS")
}

Method TestAbstractDocumentClassNames()
{
	// %Studio.AbstractDocument type that exists
	do ##class(%RoutineMgr).Delete("test2.pivot.DFI")
	do $$$AssertEquals(##class(Utils).NameToInternalName("test\_resources\dfi\test2.pivot.dfi"),"")
	do $$$AssertStatusOK(##class(Utils).ImportItem("test2.pivot.DFI"))
	do $$$AssertEquals(##class(Utils).NameToInternalName("test\_resources\dfi\test2.pivot.dfi"),"test2.pivot.DFI")
	// %Studio.AbstractDocument type that does not exist and we ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("test\_resources\dfi\DoesNotExist.dfi"),"")
	//  %Studio.AbstractDocument type that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("test\_resources\dfi\DoesNotExist.dfi", 1, 0),"DoesNotExist.DFI")
}

Method TestStaticFileNames()
{
	// Static file that shouldn't be on the server
	do $$$AssertEquals(##class(Utils).NameToInternalName("git-webui\src\js\git-webui.js"),"")
	// Static file that shouldn't be on the server but we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("git-webui\src\js\git-webui.js", 1, 0),"")
}

Method OnBeforeAllTests() As %Status
{
	set settings = ##class(SourceControl.Git.Settings).%New()
	set ..OldNamespaceTemp = settings.namespaceTemp
	set settings.namespaceTemp = $Piece(..Manager.CurrentDir,"test",1)
	$$$ThrowOnError(settings.%Save())
	merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	set $$$SourceMapping("CLS", "*") = "cls/"
	set $$$SourceMapping("DFI", "*", "NoFolders") = 1
	set $$$SourceMapping("DFI", "*") = "test/_resources/dfi/"
	quit $$$OK
}

Method %OnClose() As %Status
{
	set settings = ##class(SourceControl.Git.Settings).%New()
	set settings.namespaceTemp = ..OldNamespaceTemp
	do settings.%Save()
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
	quit $$$OK
}

}
