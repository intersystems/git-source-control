Import SourceControl.Git

Include SourceControl.Git

Class UnitTest.SourceControl.Git.NameToInternalNameTest Extends %UnitTest.TestCase
{

Property Mappings [ MultiDimensional ];

Property OldNamespaceTemp As %String;

Property OldPercentClassReplace As %String;

Method TestRegularClassNames()
{
	// Regular class that exists
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\SourceControl\Git\Utils.cls"),"SourceControl.Git.Utils.CLS")
	// Regular class that doesn't exist and we ignore non-existent classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\SourceControl\Git\DoesNotExist.cls"),"")
	// Regular class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\SourceControl\Git\DoesNotExist.cls", 1, 0),"SourceControl.Git.DoesNotExist.CLS")
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("test\UnitTest\Git\DoesNotExist.cls", 1, 0),"UnitTest.Git.DoesNotExist.CLS")
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("foo\UnitTest\Foo\Git\DoesNotExist.cls", 1, 0),"UnitTest.Foo.Git.DoesNotExist.CLS")
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("foo\UnitTest\Foo\Git\DoesNotExist.foo", 1, 0),"UnitTest.Foo.Git.DoesNotExist.FOO")
}

Method TestPercentClassNames()
{
	// % class that exists but we ignore % classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\Base.cls"),"")
	// % class that exists and we don't ignore % classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\Base.cls", 0),"%Studio.Extension.Base.CLS")
	// % class that doesn't exist and we ignore non-existent classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\DoesNotExist.cls", 0),"")
	// % class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\DoesNotExist.cls", 0, 0),"%Studio.Extension.DoesNotExist.CLS")
}

Method TestAbstractDocumentClassNames()
{
	// %Studio.AbstractDocument type that exists
	do ##class(%RoutineMgr).Delete("test2.pivot.DFI")
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("test\_resources\dfi\test2.pivot.dfi"),"")
	do $$$AssertStatusOK(##class(SourceControl.Git.Utils).ImportItem("test2.pivot.DFI",1))
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("test\_resources\dfi\test2.pivot.dfi"),"test2.pivot.DFI")
	// %Studio.AbstractDocument type that does not exist and we ignore non-existent classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("test\_resources\dfi\DoesNotExist.dfi"),"")
	//  %Studio.AbstractDocument type that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("test\_resources\dfi\DoesNotExist.dfi", 1, 0),"DoesNotExist.DFI")
}

Method TestStaticFileNames()
{
	// Static file that shouldn't be on the server
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("git-webui\src\js\git-webui.js"),"")
	// Static file that shouldn't be on the server but we don't ignore non-existent classes (000 composite score)
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("git-webui\src\js\git-webui.js", 1, 0, 1),"")
}

Method TestWebFileNames()
{
	// Get namespace-default web application and create a fake CSP file there
	set app = $System.CSP.GetDefaultApp($Namespace)
	if (app '= "") {
		set filename = app_"/unittest.csp"
		set routine = ##class(%CSP.Routine).%New(filename)
		do routine.Write("<html><head><title>Unit Test</title></head><body>It's a unit test page!</body></html>")
		do $$$AssertStatusOK(routine.%Save())
		do $$$AssertStatusOK(##class(SourceControl.Git.Utils).AddToSourceControl(filename))
		do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("csp\unittest.csp"),filename)
		do $$$AssertStatusOK(##class(SourceControl.Git.Utils).RemoveFromSourceControl(filename))
	}
}

Method TestNegative()
{
	// Based on composite scores
	 
	// 000 is covered in TestStaticFileNames()
	// 001 and 002
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("barq\MyBarFile1.barq", 1, 0, 1),"")
	// 010
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("bar\NotMyBarFile1.barq", 1, 0, 1),"")
	// 011 and 012
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("bar\MyBarFile1.barq", 1, 0, 1),"")
	// 100
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("barq\NotMyBarFile1.bar", 1, 0, 1),"")
	// 101 and 102
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("barq\MyBarFile1.bar", 1, 0, 1),"")
	// 110
	do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("bar\NotMyBarFile1.bar", 1, 0, 1),"")
}

Method TestEnvExpansion()
{
    try {
        set $$$SourceMapping("ESD","*") = "config/<env>/"
        set $$$SourceMapping("ESD","*","NoFolders") = 1
        set settings = ##class(SourceControl.Git.Settings).%New()
        set oldEnvName = settings.environmentName
        set settings.environmentName = "TEST"
        $$$ThrowOnError(settings.%Save())
        do $$$AssertEquals(##class(SourceControl.Git.Utils).NameToInternalName("config/test/Ens.Config.DefaultSettings.ESD",1,0,1),"Ens.Config.DefaultSettings.ESD")
    } catch err {
        do $$$AssertStatusOK(err.AsStatus())
    }
    if $data(settings)#2 && $data(oldEnvName)#2 {
        set settings.environmentName = oldEnvName
        $$$ThrowOnError(settings.%Save())
    }
}

Method OnBeforeAllTests() As %Status
{
	set settings = ##class(SourceControl.Git.Settings).%New()
	set ..OldNamespaceTemp = settings.namespaceTemp
	set ..OldPercentClassReplace = settings.percentClassReplace
	merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
	set folder = ##class(%File).NormalizeDirectory(##class(%Library.File).TempFilename()_"dir/")
	set settings.namespaceTemp = folder
	set settings.percentClassReplace = "_"
	$$$ThrowOnError(settings.%Save())
	do ##class(%Library.File).CopyDir($Piece(..Manager.CurrentDir,"test"),folder,1)
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	Set app = $System.CSP.GetDefaultApp($Namespace)
	If (app '= "") {
		set $$$SourceMapping("/CSP/", app) = "csp/"
	}
	set $$$SourceMapping("CLS", "*") = "cls/"
	set $$$SourceMapping("CLS", "UnitTest") = "test/"
	set $$$SourceMapping("CLS", "UnitTest.Foo") = "foo/"
	set $$$SourceMapping("FOO", "*") = "foo/"
	set $$$SourceMapping("BAR", "MyBarFile") = "bar/"
	set $$$SourceMapping("DFI", "*", "NoFolders") = 1
	set $$$SourceMapping("DFI", "*") = "test/_resources/dfi/"
	quit $$$OK
}

Method %OnClose() As %Status
{
	set settings = ##class(SourceControl.Git.Settings).%New()
	set settings.namespaceTemp = ..OldNamespaceTemp
	set settings.percentClassReplace = ..OldPercentClassReplace
	do settings.%Save()
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
	quit $$$OK
}

}
