Class UnitTest.SourceControl.Git.Utils.TakeOwnership Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestTakeOwnership()
{
    set internalName = "Test.Package.TestClass.cls"

    &sql(INSERT INTO SourceControl_Git.Change (InternalName, ChangedBy, ItemFile, Action, Committed)
         VALUES (:internalName, 'OtherUser', 'cls/Test/Package/TestClass.cls', 'edit', 0))
    $$$ThrowSQLIfError(SQLCODE,.%msg)

    try {
        // Call TakeOwnership and verify it succeeds
        do $$$AssertStatusOK(##class(SourceControl.Git.Utils).TakeOwnership(internalName))

        // Verify ChangedBy was updated
        &sql(SELECT ChangedBy INTO :changedBy FROM SourceControl_Git.Change WHERE InternalName = :internalName)
        $$$ThrowSQLIfError(SQLCODE,.%msg)
        do $$$AssertEquals(changedBy, $username)
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }

    // Clean up
    &sql(DELETE FROM SourceControl_Git.Change WHERE InternalName = :internalName)
}

}
