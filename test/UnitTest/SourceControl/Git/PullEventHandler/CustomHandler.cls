/// Tests that a pull event handler living in the repository itself can be used
/// on an instance where it has not been loaded/compiled yet - see issue #1000.
Class UnitTest.SourceControl.Git.PullEventHandler.CustomHandler Extends UnitTest.SourceControl.Git.AbstractTest
{

/// Pull event handler class defined only in the working tree at the start of each test
Parameter FixtureClass As STRING = "TestGit.PullHandlerFixture";

/// Global the fixture's OnPull() increments, to prove it actually ran
Parameter MarkerGlobal As STRING = "UnitTestPullHandlerFixture";

Method TestHandlerNotInDatabase()
{
    do ..UseFixtureHandler(1)
    set sc = ##class(SourceControl.Git.Utils).ImportAll(1)
    do $$$AssertStatusOK(sc, "ImportAll succeeds with a pull event handler that is only in the repository")
    do $$$AssertTrue($$$comClassDefined(..#FixtureClass), "pull event handler was compiled")
    do $$$AssertEquals($get(@..MarkerRef()), 1, "pull event handler's OnPull() ran once")
}

Method TestHandlerLoadedButNotCompiled()
{
    do ..UseFixtureHandler(0)
    set sc = ##class(SourceControl.Git.Utils).ImportAll(1)
    do $$$AssertStatusOK(sc, "ImportAll succeeds when items are loaded without being compiled")
    do $$$AssertTrue($$$comClassDefined(..#FixtureClass), "pull event handler was compiled")
    do $$$AssertEquals($get(@..MarkerRef()), 1, "pull event handler's OnPull() ran once")
}

Method TestUnavailableHandlerReportsError()
{
    do ..UseFixtureHandler(1)
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.pullEventClass = "TestGit.NoSuchPullHandler"
    $$$ThrowOnError(settings.%Save())

    set sc = ##class(SourceControl.Git.Utils).ImportAll(1)
    set errorText = $system.Status.GetErrorText(sc)
    do $$$AssertNotTrue($$$ISOK(sc), "ImportAll reports an error when the pull event handler cannot be loaded")
    do $$$AssertTrue($find(errorText, "TestGit.NoSuchPullHandler") > 0, "error names the unavailable pull event handler")
    do $$$AssertTrue($find(errorText, ##class(SourceControl.Git.Utils).FullExternalName("TestGit.NoSuchPullHandler.cls")) > 0, "error names the file that was looked for")
    do $$$AssertNotTrue($find(errorText, "<CLASS DOES NOT EXIST>") > 0, "error is not a raw ObjectScript error")
}

/// Writes the fixture handler to the working tree, configures it as the pull event
/// handler, and removes it from the database so it must be bootstrapped on import.
Method UseFixtureHandler(compileOnImport As %Boolean)
{
    set settings = ##class(SourceControl.Git.Settings).%New()
    set settings.pullEventClass = ..#FixtureClass
    set settings.compileOnImport = compileOnImport
    $$$ThrowOnError(settings.%Save())

    do ..WriteFile(##class(SourceControl.Git.Utils).FullExternalName(..#FixtureClass_".cls"), ..FixtureSource())
    do ..RemoveFixtureClass()
    kill @..MarkerRef()
}

ClassMethod MarkerRef() As %String [ CodeMode = expression ]
{
"^"_..#MarkerGlobal
}

ClassMethod RemoveFixtureClass()
{
    if ##class(%Dictionary.ClassDefinition).%ExistsId(..#FixtureClass) || $$$comClassDefined(..#FixtureClass) {
        $$$ThrowOnError($system.OBJ.Delete(..#FixtureClass, "-d"))
    }
    do ##class(SourceControl.Git.Utils).RemoveRoutineTSH(..#FixtureClass_".cls")
}

ClassMethod FixtureSource() As %String
{
    set lf = $char(10)
    quit "Class "_..#FixtureClass_" Extends SourceControl.Git.PullEventHandler.IncrementalLoad"_lf_
        "{"_lf_
        lf_
        "Parameter NAME = ""Unit Test Fixture"";"_lf_
        lf_
        "Parameter DESCRIPTION = ""Pull event handler used by unit tests."";"_lf_
        lf_
        "Method OnPull() As %Status"_lf_
        "{"_lf_
        "    set sc = ##super()"_lf_
        "    set ^"_..#MarkerGlobal_" = $get(^"_..#MarkerGlobal_") + 1"_lf_
        "    quit sc"_lf_
        "}"_lf_
        lf_
        "}"_lf
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
    do ..RemoveFixtureClass()
    kill @..MarkerRef()
    quit ##super()
}

}
