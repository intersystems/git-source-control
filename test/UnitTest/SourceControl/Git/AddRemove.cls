Import SourceControl.Git

Class UnitTest.SourceControl.Git.AddRemove Extends %UnitTest.TestCase
{

Method TestInit()
{
	new %SourceControl
	do ##class(%Studio.SourceControl.Interface).SourceControlCreate()
	set sc = %SourceControl.UserAction(0,"%SourceMenu,Init","","",.action,.target,.msg,.reload)
	do $$$AssertStatusOK(sc)
}

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

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Property SourceControlGlobal [ MultiDimensional ];

Method %OnNew(initvalue) As %Status
{
	Merge ..SourceControlGlobal = ^SYS("SourceControl")
	Kill ^SYS("SourceControl")
	Set folder = ##class(%Library.File).TempFilename()_"dir"
	Do ##class(%Library.File).CreateDirectory(folder)
	Set ^SYS("SourceControl","Git","settings","namespaceTemp") = folder
	Set ^SYS("SourceControl","Git","settings","mappings","MAC","*")="rtn/"
	Do ##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension")
	Quit ##super(initvalue)
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	Do ##class(%Studio.SourceControl.Interface).SourceControlClassSet(..InitialExtension)
	Kill ^SYS("SourceControl")
	Merge ^SYS("SourceControl") = ..SourceControlGlobal
	Quit $$$OK
}

}

