Include %sySecurity

Class UnitTest.SourceControl.Git.Initialization Extends %UnitTest.TestCase
{

Method TestSetupFavorites()
{
    Set page = "Git: "_$Namespace
    Set username = $Username
    &sql(delete from %SYS_Portal.Users where Page = :page and Username = :username)
    // Intentionally called twice!
    Do ##class(SourceControl.Git.Utils).ConfigureWeb()
    Do ##class(SourceControl.Git.Utils).ConfigureWeb()
    &sql(select count(*) into :favoriteCount from %SYS_Portal.Users where Page = :page and Username = :username)
    Do $$$AssertEquals(favoriteCount,1)
    Do $$$AssertTrue($$$SecurityApplicationsExists("/isc/studio/usertemplates",record))
    Do $$$AssertEquals($$$GetSecurityApplicationsGroupById(record),"%ISCMgtPortal")
}

Method TestRunGitInGarbageContext()
{
    Set settings = ##class(SourceControl.Git.Settings).%New()
    Set oldTemp = settings.namespaceTemp
    Set settings.namespaceTemp = ##class(%Library.File).TempFilename()_"nonexistentdir"
    set settings.environmentName = ""
    Do $$$AssertStatusOK(settings.%Save())
    Try {
        Do ##class(%Library.File).RemoveDirectory(settings.namespaceTemp)
        // This is a prerequisite in any testing environment.
        Write ##class(SourceControl.Git.Utils).TempFolder()
        Do $$$AssertTrue(##class(SourceControl.Git.Utils).GitBinExists())
    } Catch e {
        Do $$$AssertFailure("Error occurred: "_$System.Status.GetErrorText(e.AsStatus()))
    }
    // OK for unit test to leak this if it was empty to start
    If (oldTemp '= "") {
        Set settings.namespaceTemp = oldTemp
        Do $$$AssertStatusOK(settings.%Save())
    }
}

}

