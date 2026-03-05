Class UnitTest.SourceControl.Git.Utils.ExportItem Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Tests that ExportItem creates intermediate directories when they don't exist
Method TestExportCreatesIntermediateDirectories()
{
    set internalName = "TestGitExport.Deep.Nested.Pkg.MyClass.CLS"

    // Create the class in the database so ExportItem has something to export
    set classDef = ##class(%Dictionary.ClassDefinition).%New()
    set classDef.Name = "TestGitExport.Deep.Nested.Pkg.MyClass"
    $$$ThrowOnError(classDef.%Save())

    // Determine the expected export path and ensure its directory does NOT exist yet
    set filename = ##class(SourceControl.Git.Utils).FullExternalName(internalName)
    set dirPath = ##class(%File).GetDirectory(filename)
    if ##class(%File).DirectoryExists(dirPath) {
        do ##class(%File).RemoveDirectoryTree(dirPath)
    }
    do $$$AssertNotTrue(##class(%File).DirectoryExists(dirPath), "Directory should not exist before export")

    // Export the item - this should succeed even without pre-existing directories
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).ExportItem(internalName, 0, 1))
    do $$$AssertTrue(##class(%File).Exists(filename))

    // Clean up
    do $system.OBJ.Delete(internalName, "-d")
    if ##class(%File).Exists(filename) {
        do ##class(%File).Delete(filename)
    }
}

}
