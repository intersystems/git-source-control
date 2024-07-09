Class UnitTest.SourceControl.Git.BaselineExport Extends %UnitTest.TestCase
{

Method TestBaselineExport()
{
    // create a mac routine
	if '##class(%Routine).Exists("test.mac") {
		set r = ##class(%Routine).%New("test.mac")
		do r.WriteLine(" write 22,!")
		do r.Save()
		do r.Compile()
	}
    // create an inc routine
	if '##class(%Routine).Exists("test.inc") {
		set r = ##class(%Routine).%New("test.inc")
		do r.WriteLine(" ; test include routine")
		do r.Save()
		do r.Compile()
	}
    // create a class
    if '##class(%Dictionary.ClassDefinition).%OpenId("TestPkg.Class") {
        set class = ##class(%Dictionary.ClassDefinition).%New()
        set class.Name = "TestPkg.Class"
        $$$ThrowOnError(class.%Save())
        do $system.OBJ.Compile("TestPkg.Class")
    }
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.mac"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.inc"))
    do $$$AssertNotTrue(##class(SourceControl.Git.Utils).IsInSourceControl("TestPkg.Class.cls"))
    do $$$AssertStatusOK(##class(SourceControl.Git.API).BaselineExport())
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.mac"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("test.inc"))
    do $$$AssertTrue(##class(SourceControl.Git.Utils).IsInSourceControl("TestPkg.Class.cls"))
}

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Property SourceControlGlobal [ MultiDimensional ];

Method %OnNew(initvalue) As %Status
{
	Merge ..SourceControlGlobal = ^SYS("SourceControl")
	Kill ^SYS("SourceControl")
	Set settings = ##class(SourceControl.Git.Settings).%New()
	Set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"dir"
	Set settings.Mappings("MAC","*")="rtn/"
	Set settings.Mappings("CLS","*")="cls/"
	Do settings.%Save()
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
