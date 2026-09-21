Class UnitTest.SourceControl.Git.DeploymentLog Extends %UnitTest.TestCase
{

Method TestLogActions() {
    set log = ##class(SourceControl.Git.DeploymentLog).%New()
    set timestamp = "2026-09-10 08:20:00"  // Use a static timestamp to verify properties are set.
    do log.StartLog("face123", timestamp)
    do $$$AssertEquals(log.HeadRevision, "face123")
    do $$$AssertEquals(log.StartTimestamp, timestamp)

    do log.FinalizeLog($$$OK, timestamp)
    do $$$AssertStatusOK(log.Status)
    do $$$AssertEquals(log.EndTimestamp, timestamp)
}

}
