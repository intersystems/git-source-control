Include SourceControl.Git

Class UnitTest.SourceControl.Git.Util.Production Extends %UnitTest.TestCase
{

Property Mappings [ MultiDimensional ];

Method TestItemIsPTD()
{
    do $$$AssertNotTrue(##class(SourceControl.Git.Util.Production).ItemIsPTD("cls/test.xml"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Util.Production).ItemIsPTD("ptd/test.md"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Util.Production).ItemIsPTD(""))
    do $$$AssertTrue(##class(SourceControl.Git.Util.Production).ItemIsPTD("ptd/test.xml"))
    do $$$AssertTrue(##class(SourceControl.Git.Util.Production).ItemIsPTD("ptd2/test.xml"))
    do $$$AssertTrue(##class(SourceControl.Git.Util.Production).ItemIsPTD("ptd2\test.xml"))
}

Method TestLoadProductionsFromDirectory()
{
	// load a production from a class file under resources
	set packageRoot = ##class(SourceControl.Git.PackageManagerContext).ForInternalName("git-source-control.zpm").Package.Root
	$$$ThrowOnError($System.OBJ.Load(packageRoot_"test/_resources/cls/UnitTest/SampleProduction.cls","ck"))
	// call LoadProductionsFromDirectory on a directory under resources/ptd
	do $$$AssertStatusOK(##class(SourceControl.Git.Util.Production).LoadProductionsFromDirectory(packageRoot_"test/_resources/ptd"))
	// confirm items were deleted and added
	set itemA = ##class(Ens.Config.Production).OpenItemByConfigName("UnitTest.SampleProduction||a")
	do $$$AssertNotTrue($isobject(itemA),"item a was deleted")
	set itemB = ##class(Ens.Config.Production).OpenItemByConfigName("UnitTest.SampleProduction||b")
	do $$$AssertEquals(itemB.Settings.GetAt(1).Value,71)
	set itemB = ##class(Ens.Config.Production).OpenItemByConfigName("UnitTest.SampleProduction||c")
	do $$$AssertTrue($isobject(itemB),"item a was created")
}

Method OnBeforeAllTests() As %Status
{
	merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	set $$$SourceMapping("PTD", "*") = "ptd/"
	set $$$SourceMapping("PTD", "Some.Production") = "ptd2/"
	quit $$$OK
}

Method %OnClose() As %Status
{
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
	quit $$$OK
}

}
