Class SourceControl.Git.WebUIDriver
{

ClassMethod RunInBackground() As %Status
{
    set arg($i(arg)) = "webui"
    set arg($i(arg)) = "--repo-root"
    set arg($i(arg)) = ##class(SourceControl.Git.Utils).TempFolder()
    set arg($i(arg)) = "--no-browser"
    do $zf(-100,"/ASYNC /LOGCMD /SHELL","git",arg...)
    quit $$$OK
}

ClassMethod HandleRequest(pagePath As %String, Output handled As %Boolean = 0, Output %data As %Stream.Object)
{
    #dim %response As %CSP.Response
    #dim %request As %CSP.Request
    if $Extract(pagePath,1,5) = "/api/" {
        set handled = 1
        set %data = ##class(%Stream.FileCharacter).%New()
        if $Extract(pagePath,6,*) = "userinfo" {
            set responseJSON = ..UserInfo()
        } elseif $Extract(pagePath,6,*) = "uncommitted" {
            set responseJSON = ..Uncommitted()
        } else {
            set %response.Status = ##class(%CSP.REST).#HTTP404NOTFOUND
            set responseJSON = {"error":("invalid URI: " _ pagePath)}
        }
        if $IsObject($Get(responseJSON)) {
            do responseJSON.%ToJSON(%data)
        }
    }
}

ClassMethod UserInfo() As %SystemBase
{
    quit {
        "name": (##class(SourceControl.Git.Utils).GitUserName()),
        "email": (##class(SourceControl.Git.Utils).GitUserEmail())
    }
}

ClassMethod Uncommitted() As %SystemBase
{
    // Stub
    do ##class(Utils).GitStatus(.files)
    set output = ""
    set iter = files.%GetIterator()
    while iter.%GetNext(.key, .value) { set output = output_value_" " }
    quit {
       "output": (output)
    }
}

}

