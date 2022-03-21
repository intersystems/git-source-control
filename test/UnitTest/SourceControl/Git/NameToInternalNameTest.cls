Import SourceControl.Git

Include SourceControl.Git

Class UnitTest.SourceControl.Git.NameToInternalNameTest Extends %UnitTest.TestCase
{

Property Mappings [ MultiDimensional ];

Method TestRegularClassNames()
{
	// Regular class that exists
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\SourceControl\Git\Utils.cls"),"SourceControl.Git.Utils.CLS")
	// Regular class that doesn't exist and we ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\SourceControl\Git\DoesNotExist.cls"),"")
	// Regular class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\SourceControl\Git\DoesNotExist.cls", 1, 0),"SourceControl.Git.DoesNotExist.CLS")
}

Method TestPercentClassNames()
{
	// % class that exists but we ignore % classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\Base.cls"),"")
	// % class that exists and we don't ignore % classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\Base.cls", 0),"%Studio.Extension.Base.CLS")
	// % class that doesn't exist and we ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\DoesNotExist.cls", 0),"")
	// % class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("cls\"_##class(SourceControl.Git.Utils).PercentClassReplace()_"Studio\Extension\DoesNotExist.cls", 0, 0),"%Studio.Extension.DoesNotExist.CLS")
}

Method TestAbstractDocumentClassNames()
{
	// %Studio.AbstractDocument type that exists
	do $$$AssertEquals(##class(Utils).NameToInternalName("nspace\hl7\TestSchema.hl7"),"TestSchema.HL7")
	// %Studio.AbstractDocument type that exists with '.' in the name
	do $$$AssertEquals(##class(Utils).NameToInternalName("nspace\hl7\2.1.1.1.1.hl7"),"2.1.1.1.1.HL7")
	// %Studio.AbstractDocument type that does not exist and we ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("nspace\hl7\DoesNotExist.hl7"),"")
	//  %Studio.AbstractDocument type that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("nspace\hl7\DoesNotExist.hl7", 1, 0),"DoesNotExist.HL7")
}

Method TestStaticFileNames()
{
	// Static file that shouldn't be on the server
	do $$$AssertEquals(##class(Utils).NameToInternalName("git-webui\src\js\git-webui.js"),"")
	// Static file that shouldn't be on the server but we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).NameToInternalName("git-webui\src\js\git-webui.js", 1, 0),"")
}

Method OnBeforeAllTests() As %Status
{
	merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	set $$$SourceMapping("CLS", "*") = "cls/"
	set $$$SourceMapping("HL7", "*", "NoFolders") = "nspace/hl7/"
	quit $$$OK
}

Method %OnClose() As %Status
{
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
	quit $$$OK
}

}
