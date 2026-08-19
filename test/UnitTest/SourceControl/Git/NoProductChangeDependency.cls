/// Guards issue #989: no Embedded Git class may reference %Studio.SourceControl.Change,
/// which ships only with CCR as of IRIS 2026.3.
Class UnitTest.SourceControl.Git.NoProductChangeDependency Extends %UnitTest.TestCase
{

Method TestNoReferenceToProductChangeClass()
{
    &sql(DECLARE ClassCursor CURSOR FOR
         SELECT Name INTO :className FROM %Dictionary.ClassDefinition
         WHERE Name %STARTSWITH 'SourceControl.Git.')
    &sql(OPEN ClassCursor)
        throw:SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
    &sql(FETCH ClassCursor)
    while SQLCODE = 0 {
        $$$ThrowOnError(##class(%Compiler.UDL.TextServices).GetTextAsString($namespace, className, .source))
        do $$$AssertNotTrue(source [ "%Studio.SourceControl.Change", className_" must not reference %Studio.SourceControl.Change")
        do $$$AssertNotTrue(source [ "%Studio_SourceControl.Change", className_" must not reference %Studio_SourceControl.Change")
        &sql(FETCH ClassCursor)
    }
    &sql(CLOSE ClassCursor)
}

}
