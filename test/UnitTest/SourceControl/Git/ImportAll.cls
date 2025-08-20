Class UnitTest.SourceControl.Git.ImportAll Extends UnitTest.SourceControl.Git.AbstractTest
{

Property WebAppPath As %String;

Method %OnNew(initvalue) As %Status
{
	$$$QuitOnError(##super(initvalue))
	Kill ^SYS("SourceControl")
	/// add mappings for MAC and CSP
	Set settings = ##class(SourceControl.Git.Settings).%New()
	Set settings.Mappings("MAC","*")="rtn/"
	Set settings.Mappings("/CSP/","/csp/git/unittest/xsl")="csp/git/unittest/xsl"
	$$$ThrowOnError(settings.%Save())
	set ..WebAppPath = ##class(%File).TempFilename()_"d"
	do ##class(%File).CreateDirectoryChain(..WebAppPath)
	do ..CreateTestWebApp("/csp/git/unittest/xsl", ..WebAppPath)
	return $$$OK
}

ClassMethod CreateTestWebApp(name, path)
{
	new $namespace
	set $namespace = "%SYS"
	kill props
	set props("Path") = path
	if '##class(Security.Applications).Exists(name) {
		$$$ThrowOnError(##class(Security.Applications).Create(name, .props))
	} else {
		$$$ThrowOnError(##class(Security.Applications).Create(name, .props))
	}
}

ClassMethod DeleteTestWebApp(name)
{
	
	new $namespace
	set $namespace = "%SYS"
	if ##class(Security.Applications).Exists(name) {
		$$$ThrowOnError(##class(Security.Applications).Delete(name))
	}
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
	do ..DeleteTestWebApp("/csp/git/unittest/xsl")
	do ##class(%File).RemoveDirectoryTree(..WebAppPath)
	quit ##super()
}

Method TestImportAll()
{
	do ..CreateTestRoutine()
	$$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl("test.mac"))
	do ..CreateStrayFileInRtn()
	do ..WriteFile(##class(SourceControl.Git.Settings).%New().namespaceTemp_"csp/git/unittest/xsl/test.xsl", "<?xml version=""1.0"" encoding=""UTF-8""?> <xsl:stylesheet version=""1.0""></xsl:stylesheet>")
	$$$ThrowOnError(##class(%Routine).Delete("test.mac"))
	do ##class(%RoutineMgr).Delete("/csp/git/unittest/xsl/test.xsl")
	$$$ThrowOnError(##class(SourceControl.Git.Utils).ImportAll(1))
	do $$$AssertTrue(##class(%Routine).Exists("test.mac"))
	do $$$AssertTrue(##class(%RoutineMgr).Exists("/csp/git/unittest/xsl/test.xsl"))
	do $$$AssertFilesSame(##class(SourceControl.Git.Settings).%New().namespaceTemp_"csp/git/unittest/xsl/test.xsl", ..WebAppPath_"/test.xsl")
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
