Include %occInclude

Class UnitTest.SourceControl.Git.Change Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Creates a real file on disk, since SetUncommitted rejects files that do not exist
ClassMethod TempFile() As %String
{
    set path = ##class(%File).TempFilename("txt")
    do ..WriteFile(path, "test contents")
    quit ##class(%File).NormalizeFilename(path)
}

ClassMethod Cleanup(filename As %String)
{
    &sql(DELETE FROM SourceControl_Git.Change WHERE ItemFile = :filename)
    do ##class(%File).Delete(filename)
}

Method TestSetAndGetUncommitted()
{
    set filename = ..TempFile()
    try {
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", "Test.Git.Change.cls", $username, "terminal", 1, "", "")
        do $$$AssertStatusOK(sc)
        do $$$AssertTrue(##class(SourceControl.Git.Change).IsUncommitted(filename))

        set sc = ##class(SourceControl.Git.Change).GetUncommitted(filename, .action, .internalName, .changedBy, .source, .updated)
        do $$$AssertStatusOK(sc)
        do $$$AssertEquals(action, "edit")
        do $$$AssertEquals(internalName, "Test.Git.Change.cls")
        do $$$AssertEquals(changedBy, $username)
        do $$$AssertEquals(source, "terminal")
        do $$$AssertNotEquals(updated, "")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(filename)
}

/// ChangedBy defaults to $username and Name defaults to InternalName in %OnAddToSaveSet
Method TestDefaultsOnSave()
{
    set filename = ..TempFile()
    try {
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(filename, "add", "Test.Git.Defaults.cls", "", "", 0, "", "")
        do $$$AssertStatusOK(sc)

        &sql(SELECT ChangedBy, Name INTO :changedBy, :name
             FROM SourceControl_Git.Change WHERE ItemFile = :filename)
        $$$ThrowSQLIfError(SQLCODE,.%msg)
        do $$$AssertEquals(changedBy, $username)
        do $$$AssertEquals(name, "Test.Git.Defaults.cls")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(filename)
}

/// A second SetUncommitted for the same file routes through UpdateUncommitted
Method TestSetUncommittedUpdatesExistingRow()
{
    set filename = ..TempFile()
    try {
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(filename, "add", "Test.Git.Update.cls", $username, "", 0, "", "")
        do $$$AssertStatusOK(sc)
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", "Test.Git.Update.cls", $username, "", 0, "", "")
        do $$$AssertStatusOK(sc)

        &sql(SELECT COUNT(*) INTO :rowCount
             FROM SourceControl_Git.Change WHERE ItemFile = :filename)
        $$$ThrowSQLIfError(SQLCODE,.%msg)
        do $$$AssertEquals(rowCount, 1)

        set sc = ##class(SourceControl.Git.Change).GetUncommitted(filename, .action)
        do $$$AssertStatusOK(sc)
        do $$$AssertEquals(action, "edit")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(filename)
}

/// A change owned by another user cannot be updated
Method TestUpdateByOtherUserFails()
{
    set filename = ..TempFile()
    try {
        &sql(INSERT INTO SourceControl_Git.Change (InternalName, ChangedBy, ItemFile, Action, Committed)
             VALUES ('Test.Git.Other.cls', 'OtherUser', :filename, 'edit', 0))
        $$$ThrowSQLIfError(SQLCODE,.%msg)

        set sc = ##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", "Test.Git.Other.cls", $username, "", 0, "", "")
        do $$$AssertTrue($$$ISERR(sc))
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(filename)
}

/// ListUncommitted hides 'revert' rows unless IncludeRevert is set
Method TestListUncommittedRevertFiltering()
{
    set editFile = ..TempFile()
    set revertFile = ..TempFile()
    try {
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(editFile, "edit", "Test.Git.ListEdit.cls", $username, "", 0, "", "")
        do $$$AssertStatusOK(sc)
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(revertFile, "revert", "Test.Git.ListRevert.cls", $username, "", 0, "", "")
        do $$$AssertStatusOK(sc)

        set sc = ##class(SourceControl.Git.Change).ListUncommitted(.withoutRevert)
        do $$$AssertStatusOK(sc)
        do $$$AssertTrue($data(withoutRevert(editFile)))
        do $$$AssertNotTrue($data(withoutRevert(revertFile)))

        set sc = ##class(SourceControl.Git.Change).ListUncommitted(.withRevert, 1)
        do $$$AssertStatusOK(sc)
        do $$$AssertTrue($data(withRevert(editFile)))
        do $$$AssertTrue($data(withRevert(revertFile)))
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(editFile)
    do ..Cleanup(revertFile)
}

Method TestSetUncommittedRejectsMissingFile()
{
    set filename = ##class(%File).NormalizeFilename(##class(%File).TempFilename("txt"))
    do ##class(%File).Delete(filename)
    set sc = ##class(SourceControl.Git.Change).SetUncommitted(
        filename, "edit", "Test.Git.Missing.cls", $username, "", 0, "", "")
    do $$$AssertTrue($$$ISERR(sc))
}

/// A row carrying an extra trailing $list piece (the orphaned Bulk slot left behind by
/// rows written before this class stopped inheriting from %Studio.SourceControl.Change)
/// must still read back correctly.
Method TestRowWithOrphanedTrailingSlotIsReadable()
{
    set filename = ..TempFile()
    try {
        set sc = ##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", "Test.Git.OldLayout.cls", $username, "terminal", 1, "", "")
        do $$$AssertStatusOK(sc)
        do $$$AssertTrue(##class(SourceControl.Git.Change).IsUncommitted(filename, .id))

        // simulate the pre-change on-disk layout, which had a 15th piece for Bulk
        set $list(^Studio.SourceControl.ChangeD(id), 15) = 1

        set sc = ##class(SourceControl.Git.Change).GetUncommitted(filename, .action, .internalName, .changedBy, .source)
        do $$$AssertStatusOK(sc)
        do $$$AssertEquals(action, "edit")
        do $$$AssertEquals(internalName, "Test.Git.OldLayout.cls")
        do $$$AssertEquals(changedBy, $username)
        do $$$AssertEquals(source, "terminal")

        set obj = ##class(SourceControl.Git.Change).%OpenId(id)
        do $$$AssertTrue($isobject(obj))
        do $$$AssertEquals(obj.Action, "edit")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(filename)
}

/// GetUserProductionChanges must read the Embedded Git change table, not the product one.
/// Note: This test documents the intent to query SourceControl_Git.Change directly, but cannot
/// detect a regression in environments where both %Studio.SourceControl.Change and SourceControl_Git.Change
/// map to the same physical globals (^Studio.SourceControl.ChangeD/I) — a deliberate design choice
/// documented in the spec's "Storage and data" section to make the upgrade a no-op. The old and new queries
/// return identical results in such environments. The test only genuinely guards the regression once
/// %Studio.SourceControl.Change is fully removed from an instance (2026.3 target), at which point the old
/// query would SQL-error. Until then, this test has practical value as documentation of query correctness and
/// intent rather than as a live regression detector.
Method TestGetUserProductionChanges()
{
    set filename = ..TempFile()
    set internalName = "TestGit.UnitTestProduction.Production||TestGit.UnitTestItem"
    set user = $username
    try {
        &sql(INSERT INTO SourceControl_Git.Change (InternalName, ChangedBy, ItemFile, Action, Committed)
             VALUES (:internalName, :user, :filename, 'edit', 0))
        $$$ThrowSQLIfError(SQLCODE,.%msg)

        do ##class(SourceControl.Git.Production).GetUserProductionChanges(
            "TestGit.UnitTestProduction.Production", .items)
        do $$$AssertTrue($data(items(internalName)))
        do $$$AssertEquals($get(items(internalName)), "edit")
    } catch ex {
        do $$$AssertStatusOK(ex.AsStatus())
    }
    do ..Cleanup(filename)
}

}
