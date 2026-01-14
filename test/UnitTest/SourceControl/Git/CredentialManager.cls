Class UnitTest.SourceControl.Git.CredentialManager Extends %UnitTest.TestCase
{

Method TestAccessToken()
{
    // Stop the memory store to ensure a clean state
	Do ##class(SourceControl.Git.Util.CredentialManager).StopMemoryStore()

    // Make sure there is no token for the user
	set username = "testUser"
    do ##class(SourceControl.Git.Util.CredentialManager).DeleteAccessToken(username, .err, .code)
    do $$$AssertEquals(err, "")
    do $$$AssertEquals(code, 1)

	w !,"Getting token for user """_username_""", expect error", !
	set token = ##class(SourceControl.Git.Util.CredentialManager).GetAccessToken(username, .err, .code)
	do $$$AssertEquals(token, "")
    do $$$AssertEquals(err, "")
    do $$$AssertEquals(code, 1)

	set token = "testToken"
	w !, "Setting token """_token_""" for user """_username_"""", !
	do ##class(SourceControl.Git.Util.CredentialManager).SetAccessToken(username, token, .err, .code)
    do $$$AssertEquals(err, "")
    do $$$AssertEquals(code, 1)

	w !, "Getting token for user "_username_", expect to get token """_token_"""", !
	set token = ##class(SourceControl.Git.Util.CredentialManager).GetAccessToken(username, .err, .code)
	do $$$AssertEquals(token, "testToken")
    do $$$AssertEquals(err, "")
    do $$$AssertEquals(code, 1)
}

}
