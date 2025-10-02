Class UnitTest.SourceControl.Git.AbstractTest Extends %UnitTest.TestCase
{

Property InitialExtension As %String [ InitialExpression = {##class(%Studio.SourceControl.Interface).SourceControlClassGet()} ];

Property SourceControlGlobal [ MultiDimensional ];

Method %OnNew(initvalue) As %Status
{
	Merge ..SourceControlGlobal = ^SYS("SourceControl")
	Kill ^SYS("SourceControl")
	Set settings = ##class(SourceControl.Git.Settings).%New()
	Set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"dir"
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

ClassMethod WriteFile(filePath, contents)
{
    set dirPath = ##class(%File).GetDirectory(filePath)
    if '##class(%File).CreateDirectoryChain(dirPath,.ret) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"failed to create directory: "_ret))
    }
    set fileStream = ##class(%Stream.FileCharacter).%OpenId(filePath,,.sc)
    $$$ThrowOnError(sc)
    do fileStream.Write(contents)
    $$$ThrowOnError(fileStream.%Save())
}

ClassMethod ResetLocalRepo()
{
    set localRepo = ##class(SourceControl.Git.Settings).%New().namespaceTemp
    do ##class(%File).RemoveDirectoryTree(localRepo)
    do ##class(%File).CreateDirectoryChain(localRepo)
}

}
