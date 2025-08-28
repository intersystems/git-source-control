Class UnitTest.SourceControl.Git.WebUIDriver Extends UnitTest.SourceControl.Git.AbstractTest
{

Method TestRevertManyFiles()
{
    set oldSession = $get(%session), oldRequest = $get(%request), oldResponse = $get(%response)
    set %session = ##class(%CSP.Session).%New(999,0)
    set %request = ##class(%CSP.Request).%New()
    set %response = ##class(%CSP.Response).%New()
	do ##class(SourceControl.Git.Utils).Init()
    set requestBody = {"command": ["clean","-f","--"]}
    for i=1:1:500 {
        set fileRelPath = "txt/test"_i_".txt"
        do ..WriteFile(..TempGitRepoPath_"/"_fileRelPath, "automated testing")
        do requestBody.command.%Push(fileRelPath)
    }
    do $$$AssertTrue(##class(%File).Exists(..TempGitRepoPath_"/txt/test1.txt"))
    do $$$AssertTrue(##class(%File).Exists(..TempGitRepoPath_"/txt/test500.txt"))
    set %request.Content = ##class(%CSP.CharacterStream).%New()
    set %request.Method = "POST"
    do requestBody.%ToJSON(%request.Content)
    do ##class(SourceControl.Git.WebUIDriver).HandleRequest("/git-command",,.handled,.data)
    do $$$LogMessage(data.Read())
    do $$$AssertTrue(handled)
    do $$$AssertNotTrue(##class(%File).Exists(..TempGitRepoPath_"/txt/test1.txt"))
    do $$$AssertNotTrue(##class(%File).Exists(..TempGitRepoPath_"/txt/test500.txt"))
    set %session = $get(oldSession), %request = $get(oldRequest), %response = $get(oldResponse)
}

}
