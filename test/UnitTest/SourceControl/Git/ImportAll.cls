Class UnitTest.SourceControl.Git.ImportAll Extends %UnitTest.TestCase
{

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Property SourceControlGlobal [ MultiDimensional ];

Method %OnNew(initvalue) As %Status
{
	Merge ..SourceControlGlobal = ^SYS("SourceControl")
	Kill ^SYS("SourceControl")
	Set settings = ##class(SourceControl.Git.Settings).%New()
	Set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"dir"
	Set settings.Mappings("MAC","*")="rtn/"
	$$$ThrowOnError(settings.%Save())
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

Method TestImportAll()
{
	do ..CreateTestRoutine()
	$$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl("test.mac"))
	do ..CreateStrayFileInRtn()
	$$$ThrowOnError(##class(%Routine).Delete("test.mac"))
	$$$ThrowOnError(##class(SourceControl.Git.Utils).ImportAll(1))
	do $$$AssertTrue(##class(%Routine).Exists("test.mac"))
}

Method CreateTestRoutine()
{
	if '##class(%Routine).Exists("test.mac") {
		set r = ##class(%Routine).%New("test.mac")
		do r.WriteLine(" write 22,!")
		do r.Save()
		do r.Compile()
	}
}

/// creates a text file in the routines directory that is not really a routine
Method CreateStrayFileInRtn()
{
	set fileStream = ##class(%Stream.FileCharacter).%OpenId(
			##class(%File).NormalizeFilename(
				"test.txt",
				##class(%File).GetDirectory(##class(SourceControl.Git.Utils).FullExternalName("test.mac")))
			,,.sc)
	$$$ThrowOnError(sc)
	$$$ThrowOnError(fileStream.Write("hello world!"))
	$$$ThrowOnError(fileStream.%Save())
}

}
