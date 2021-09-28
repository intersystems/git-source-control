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

// this is to test git fetch

ClassMethod HandleRequest(pagePath As %String, Output handled As %Boolean = 0, Output %data As %Stream.Object)
{
    #dim %response As %CSP.Response
    #dim %request As %CSP.Request
    set pathStart = $Piece(pagePath,"/",2)
    if pathStart = "api" {
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
    } else {
        if (%request.Method = "GET") {
            // Python backend:
            /*
            def do_GET(self):
                if self.path.startswith("/git/cat-file/"):
                    obj = self.path[14:]
                    self.process(["git", "-c", "color.ui=false", "cat-file", "-p", obj], b"", True, False)
                elif self.path == "/dirname":
                    wc = os.path.split(WebUiRequestHandler.REPO_ROOT)[1]
                    self.send_text(200, codecs.encode(wc, "utf-8"))
                elif self.path == "/hostname":
                    self.send_text(200, codecs.encode(socket.gethostname(), "utf-8"))
                elif self.path == "/viewonly":
                    vo = "1" if self.is_view_only() else "0"
                    self.send_text(200, codecs.encode(vo, "utf-8"))
                elif self.is_git_request():
                    self.process_http_backend()
                else:
                    SimpleHTTPRequestHandler.do_GET(self)
            */
        } elseif (%request.Method = "POST") {
            /*
            def do_POST(self):
                if self.path == "/git":
                    content_length = int(self.headers["Content-Length"])
                    content = self.rfile.read(content_length)
                    # Convention : First line = git arguments, rest = git process stdin
                    i = content.find(b'\n')
                    if i != -1:
                        args = content[:i]
                        stdin = content[i + 1:]
                    else:
                        args = content
                        stdin = b""
                    if sys.version > '3':
                        args = codecs.decode(args, "utf-8")
                    cmd = shlex.split("git -c color.ui=true " + args)
                    action = cmd[3]
                    if not self.is_view_only() or args in ["branch", "branch --remotes", "tag"] or action in ["show", "status", "log", "ls-tree"]:
                        self.process(cmd, stdin, True, True)
                    else:
                        self.send_error(403)
                elif self.is_git_request():
                    self.process_http_backend()
                else:
                    SimpleHTTPRequestHandler.do_POST(self)
            */
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
    Set key = ""

    Set array = []
    Set key = ""
    For {
        Set key = $Order(files(key),1,fileData)
        Quit:key=""
        // Check that current user has files(key) uncommitted and only %Push if they do
        Set filename = ##class(Utils).FullExternalName(key)
        Set sc=##class(SourceControl.Git.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
			If $$$ISOK(sc) && ($D(tAction)&&(UncommittedUser=$USERNAME)) {
				Do array.%Push($ListGet(fileData,2))
			} 
    }
    quit array
}

}

