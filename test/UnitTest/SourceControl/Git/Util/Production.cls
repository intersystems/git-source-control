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
