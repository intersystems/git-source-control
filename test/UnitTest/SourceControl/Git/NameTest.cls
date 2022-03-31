Import SourceControl.Git

Include SourceControl.Git

Class UnitTest.SourceControl.Git.NameTest Extends %UnitTest.TestCase
{

Property Mappings [ MultiDimensional ];

Method TestNoExtension()
{
    // This method will test a case where the passed filename has no extension.
    // We should return an empty string in this case.
    do $$$AssertEquals(##class(Utils).Name("Test"),"")
}

Method TestNonExistantMappings()
{
   
    // This method will test cases where no mapping exists for some or all files of a certain file type.
    // Default behaviour should be followed here - the path should be "<file_extension>/<filename>"
    // Example: For "ABC.def.ghi.xzy", the output should be "xzy/ABC.def.ghi.xzy"

	// No mapping
	do $$$AssertEquals(##class(Utils).Name("Name.OtherName.OtherMoreDifferentName.xzy"),"xzy/Name.OtherName.OtherMoreDifferentName.xzy")
	// Mappings for some files
	do $$$AssertEquals(##class(Utils).Name("Name.OtherName.OtherMoreDifferentName.acb"),"acb/Name.OtherName.OtherMoreDifferentName.acb")
	// Regular class that doesn't exist and we don't ignore non-existent classes
	do $$$AssertEquals(##class(Utils).Name("XZYName.OtherName.OtherMoreDifferentName.acb"),"acb/XZYName/OtherName/OtherMoreDifferentName.acb")
}

Method TestBasicMappings()
{
   
    // This method will test cases where a mapping exists for all files of a certain file type with foldering enable.
    // This is the most simple usecase for the Name() method.

	// File corresponding to a universal mapping with foldering enabled
	do $$$AssertEquals(##class(Utils).Name("SourceControl.Git.Utils.cls"),"cls/SourceControl/Git/Utils.cls")
	// File corresponding to a specific mapping with foldering enabled
	do $$$AssertEquals(##class(Utils).Name("UnitTest.SourceControl.Git.NameTest.cls"),"test/UnitTest/SourceControl/Git/NameTest.cls")
	// File corresponding to a universal mapping with special handling
	do $$$AssertEquals(##class(Utils).Name("test2.pivot.dfi"),"test/_resources/dfi/test2.pivot.dfi")
}

Method TestOnlyNoFolders()
{
    // This method will test cases where a mapping exists for all files of a certain file type with foldering disabled.
    do $$$AssertEquals(##class(Utils).Name("Name.OtherName.OtherMoreDifferentName.nf"),"nf/sf/Name.OtherName.OtherMoreDifferentName.nf")
}

Method TestMixedFoldering()
{
    // This method will test cases where multiple mappings exist a file type with mix od foldering enabled and disabled. 
    // There are 3 cases here.
    // 1. Foldering is enabled for the universal mapping but is disabled for some packages.
    // 2. Foldering is disabled for the universal mapping but is enabled for some packages. 
    // 3. There is no specified universal mapping, so default behaviour (no foldering) should apply. But there are specific mappings for certain packages. 
    // 3 is covered in a previous test.

    // 1
    do $$$AssertEquals(##class(Utils).Name("TestPackage.Hello.World.inc"),"inc/TestPackage.Hello.World.inc")
    // 2
    do $$$AssertEquals(##class(Utils).Name("TestPackage.Hello.World.mac"),"rtn/TestPackage/Hello/World.mac")
}

Method OnBeforeAllTests() As %Status
{
	merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	
    set $$$SourceMapping("ACB","XZY")="acb/"

    set $$$SourceMapping("CLS", "*") = "cls/"
    set $$$SourceMapping("CLS", "UnitTest") = "test/"
    set $$$SourceMapping("DFI", "*", "NoFolders") = 1
	set $$$SourceMapping("DFI", "*") = "test/_resources/dfi/"

    set $$$SourceMapping("NF", "*", "NoFolders") = 1
    set $$$SourceMapping("NF", "*") = "nf/sf/"

    set $$$SourceMapping("CLS", "Hello", "NoFolders") = 1
    set $$$SourceMapping("CLS", "Hello") = "hello/"

    set $$$SourceMapping("MAC","*")="rtn/"
    set $$$SourceMapping("MAC","*","NoFolders")=1
    set $$$SourceMapping("MAC","TestPackage")="rtn/"

	quit $$$OK
}

Method %OnClose() As %Status
{
	kill @##class(SourceControl.Git.Utils).MappingsNode()
	merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
	quit $$$OK
}

}

