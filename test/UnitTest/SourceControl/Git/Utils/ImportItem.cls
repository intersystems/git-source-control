Class UnitTest.SourceControl.Git.Utils.ImportItem Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Tests that ImportItem does not store a negative error code in the TSH global
/// and that GetTempFileAndRoutineTS does not throw <VALUE OUT OF RANGE> when
/// a negative value is already stored.
Method TestNegativeTSHNotStored()
{
    set internalName = "TestGitImport.NegTSH.CLS"

    // Write a valid class file to disk so ImportItem can load it
    set filename = ##class(SourceControl.Git.Utils).FullExternalName(internalName)
    do ..WriteFile(filename, "Class TestGitImport.NegTSH {}")
    set sc = ##class(SourceControl.Git.Utils).ImportItem(internalName, 1, 0)
    do $$$AssertStatusOK(sc, "ImportItem should succeed")

    // Verify the stored TSH value is not negative
    set storedTSH = $get(^SYS("SourceControl","Git","TSH",internalName))
    if (storedTSH '= "") {
        do $$$AssertTrue(storedTSH '< 0, "Stored TSH should not be negative, got: "_storedTSH)
    }

    // Now simulate the bug: manually store a negative value in the TSH global
    // as would happen on older versions when GetFileDateModified returned an error code
    set ^SYS("SourceControl","Git","TSH",internalName) = -1
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).ImportItem(internalName, 0, 0))

    // Clean up
    kill ^SYS("SourceControl","Git","TSH",internalName)
    do $system.OBJ.Delete(internalName, "-d")
    set filename = ##class(SourceControl.Git.Utils).FullExternalName(internalName)
    if ##class(%File).Exists(filename) {
        do ##class(%File).Delete(filename)
    }
}

}
