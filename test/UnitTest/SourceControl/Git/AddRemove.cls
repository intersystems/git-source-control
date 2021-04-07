Import SourceControl.Git

Class UnitTest.SourceControl.Git.AddRemove Extends %UnitTest.TestCase
{

Method TestMac()
{
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.mac"),0)
	do $$$AssertStatusOK(##class(Utils).AddToSourceControl("test.mac"))
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.mac"),1)
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.MAC"),1)
	do $$$AssertStatusOK(##class(Utils).RemoveFromSourceControl("test.mac"))
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.mac"),0)
}

Method TestMACInUpperCase()
{
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.mac"),0)
	do $$$AssertStatusOK(##class(Utils).AddToSourceControl("test.MAC"))
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.mac"),1)
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.MAC"),1)
	do $$$AssertStatusOK(##class(Utils).RemoveFromSourceControl("test.mac"))
	do $$$AssertEquals(##class(Utils).IsInSourceControl("test.mac"),0)
}

Method OnBeforeAllTests() As %Status
{
	if '##class(%Routine).Exists("test.mac") {
		set r = ##class(%Routine).%New("test.mac")
		do r.WriteLine(" write 22,!")
		do r.Save()
		do r.Compile()
	}
	quit $$$OK
}

}

