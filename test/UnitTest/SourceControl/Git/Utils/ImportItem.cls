Include SourceControl.Git

Class UnitTest.SourceControl.Git.Utils.ImportItem Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Tests that non-ASCII characters in a lookup table survive an export/import
/// round trip. Lookup tables are Studio user documents, so ImportItem reads them
/// with a %Stream.FileCharacter; if that stream's TranslateTable does not match
/// the UTF-8 that ExportUDL writes, the UTF-8 bytes are decoded one byte at a
/// time and "µ" (one char) becomes "Âµ" (two chars). (#990)
Method TestLookupTableUnicodeRoundTrip()
{
    if '##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
        do $$$LogMessage("Not an interoperability namespace, skipping lookup table test")
        quit
    }

    set tableName = "UnitTestGitUnicode"
    set internalName = tableName_".LUT"
    // U+00B5 MICRO SIGN: one character, encoded in UTF-8 as the two bytes $c(194,181)
    set micro = $char(181)
    set expectedKey = micro_"mol/L"
    set expectedValue = micro_"g/dL"

    set $$$SourceMapping("LUT","*") = "data/lut/"
    set $$$SourceMapping("LUT","*","NoFolders") = 1

    do ..DeleteLookupTable(tableName)
    set rs = ##class(%SQL.Statement).%ExecDirect(,"INSERT INTO Ens_Util.LookupTable (TableName,KeyName,DataValue) VALUES (?,?,?)",tableName,expectedKey,expectedValue)
    $$$ThrowSQLIfError(rs.%SQLCODE, rs.%Message)
    do $$$AssertTrue(##class(%RoutineMgr).Exists(internalName), "lookup table document exists after seeding")

    set filename = ##class(SourceControl.Git.Utils).FullExternalName(internalName)
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).ExportItem(internalName, 1, 1))

    // Pin the on-disk encoding. Without this the round trip could pass with both
    // halves consistently wrong, and the regression would go unnoticed.
    set onDisk = ..ReadBytes(filename)
    do $$$AssertTrue($find(onDisk, $char(194)_$char(181)) > 0, "exported file encodes the micro sign as UTF-8 $c(194,181)")
    do $$$AssertTrue($find(onDisk, $char(195)_$char(130)) = 0, "exported file is not double-encoded")

    // Drop the in-database copy so the import has to rebuild it from the file,
    // which is what a branch switch or merge does.
    do ..DeleteLookupTable(tableName)
    do $$$AssertStatusOK(##class(SourceControl.Git.Utils).ImportItem(internalName, 1, 0), "ImportItem succeeds")

    set rs = ##class(%SQL.Statement).%ExecDirect(,"SELECT KeyName,DataValue FROM Ens_Util.LookupTable WHERE TableName=?",tableName)
    $$$ThrowSQLIfError(rs.%SQLCODE, rs.%Message)
    do $$$AssertTrue(rs.%Next(), "lookup table has a row after import")
    set actualKey = rs.KeyName
    set actualValue = rs.DataValue

    // Assert on character codes, not on string equality: the terminal and any
    // string comparison can both render mangled text as if it were correct.
    do $$$AssertEquals($length(actualKey), $length(expectedKey), "imported key length is unchanged (mangling adds a character)")
    do $$$AssertEquals($ascii(actualKey, 1), 181, "imported key starts with the micro sign, not $c(194)")
    do $$$AssertEquals(actualKey, expectedKey, "imported key round trips")
    do $$$AssertEquals($ascii(actualValue, 1), 181, "imported value starts with the micro sign, not $c(194)")
    do $$$AssertEquals(actualValue, expectedValue, "imported value round trips")

    do ..DeleteLookupTable(tableName)
    if ##class(%File).Exists(filename) {
        do ##class(%File).Delete(filename)
    }
    kill ^SYS("SourceControl","Git","TSH",internalName)
}

/// Reads a file one byte per character so callers can assert on exact encoding.
ClassMethod ReadBytes(filePath) As %String [ Private ]
{
    set stream = ##class(%Stream.FileBinary).%New()
    $$$ThrowOnError(stream.LinkToFile(filePath))
    set bytes = ""
    while 'stream.AtEnd {
        set bytes = bytes_stream.Read(4096)
    }
    quit bytes
}

ClassMethod DeleteLookupTable(tableName) [ Private ]
{
    do ##class(%SQL.Statement).%ExecDirect(,"DELETE FROM Ens_Util.LookupTable WHERE TableName=?",tableName)
}

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
