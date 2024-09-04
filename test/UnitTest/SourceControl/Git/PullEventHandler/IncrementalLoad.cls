Include SourceControl.Git

Class UnitTest.SourceControl.Git.PullEventHandler.IncrementalLoad Extends %UnitTest.TestCase
{

Property Mappings [ MultiDimensional ];

Method TestItemIsPTD()
{
    do $$$AssertNotTrue(##class(SourceControl.Git.PullEventHandler.IncrementalLoad).ItemIsPTD("cls/test.xml"))
    do $$$AssertNotTrue(##class(SourceControl.Git.PullEventHandler.IncrementalLoad).ItemIsPTD("ptd/test.md"))
    do $$$AssertNotTrue(##class(SourceControl.Git.PullEventHandler.IncrementalLoad).ItemIsPTD(""))
    do $$$AssertTrue(##class(SourceControl.Git.PullEventHandler.IncrementalLoad).ItemIsPTD("ptd/test.xml"))
    do $$$AssertTrue(##class(SourceControl.Git.PullEventHandler.IncrementalLoad).ItemIsPTD("ptd2/test.xml"))
    do $$$AssertTrue(##class(SourceControl.Git.PullEventHandler.IncrementalLoad).ItemIsPTD("ptd2\test.xml"))
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
