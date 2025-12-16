Class UnitTest.SourceControl.Git.Extension Extends %UnitTest.TestCase
{

Method TestGeneratedFilesReadOnlyOption()
{
    set sc = $$$OK
    set classCreated = 0
    try {
        do $System.OBJ.Delete("UnitTest.SourceControl.Git.GeneratedReadOnly")
        set classDef = ##class(%Dictionary.ClassDefinition).%New()
        set classDef.Name = "UnitTest.SourceControl.Git.GeneratedReadOnly"
        set classDef.GeneratedBy = "UnitTest.SourceControl.Git.GeneratedBy"
        $$$ThrowOnError(classDef.%Save())
        $$$ThrowOnError($System.OBJ.Compile("UnitTest.SourceControl.Git.GeneratedReadOnly", "ck"))
        set classCreated = 1

        set settings = ##class(SourceControl.Git.Settings).%New()
        set settings.generatedFilesReadOnly = 0
        $$$ThrowOnError(settings.%Save())
        set extension = ##class(SourceControl.Git.Extension).%New("")
        do $$$AssertNotTrue(extension.IsReadOnly("UnitTest.SourceControl.Git.GeneratedReadOnly.cls"))

        set settings.generatedFilesReadOnly = 1
        $$$ThrowOnError(settings.%Save())
        do $$$AssertTrue(extension.IsReadOnly("UnitTest.SourceControl.Git.GeneratedReadOnly.cls"))
    } catch err {
        set sc = err.AsStatus()
    }
    if classCreated {
        do $System.OBJ.Delete("UnitTest.SourceControl.Git.GeneratedReadOnly")
    }
    $$$ThrowOnError(sc)
}

}