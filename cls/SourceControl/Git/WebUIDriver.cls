Class SourceControl.Git.WebUIDriver
{

ClassMethod HandleRequest(pagePath As %String, InternalName As %String = "", Output handled As %Boolean = 0, Output %data As %Stream.Object)
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    kill %data
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
    } elseif $Match(pathStart,"git|dirname|hostname|viewonly") {
        if (%request.Method = "GET") {
            set %data = ##class(%Stream.TmpCharacter).%New()
            // Things not handled from Python backend:
            /*
            def do_GET(self):
                elif self.is_git_request():
                    self.process_http_backend()
                else:
                    SimpleHTTPRequestHandler.do_GET(self)
            */
            if (pathStart = "git") {
                if $Piece(pagePath,"/",3) = "cat-file" {
                    /*
                    if self.path.startswith("/git/cat-file/"):
                        obj = self.path[14:]
                        self.process(["git", "-c", "color.ui=false", "cat-file", "-p", obj], b"", True, False)
                    */
                    set file = $Piece(pagePath,"/",4,*)
                    do ##class(SourceControl.Git.Utils).RunGitCommand("-c",,.%data,"color.ui=false","cat-file","-p",file)
                    set handled = 1
                }
            } elseif (pathStart = "hostname") {
                /*
                elif self.path == "/hostname":
                    self.send_text(200, codecs.encode(socket.gethostname(), "utf-8"))
                */
                do %data.Write(##class(%SYS.System).GetNodeName())
                set handled = 1
            } elseif (pathStart = "viewonly") {
                /*
                elif self.path == "/viewonly":
                    vo = "1" if self.is_view_only() else "0"
                    self.send_text(200, codecs.encode(vo, "utf-8"))
                */
                // Never view-only
                do %data.Write(0)
                set handled = 1
            } elseif (pathStart = "dirname") {
                /*
                elif self.path == "/dirname":
                    wc = os.path.split(WebUiRequestHandler.REPO_ROOT)[1]
                    self.send_text(200, codecs.encode(wc, "utf-8"))
                */
                do %data.Write(##class(SourceControl.Git.Utils).TempFolder())
                set handled = 1
            }
        } elseif (%request.Method = "POST") {
            // Things not handled from Python backend:
            /*
                elif self.is_git_request():
                    self.process_http_backend()
                else:
                    SimpleHTTPRequestHandler.do_POST(self)
            */
            if (pathStart = "git") {
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
                */
                set reference = "%request.Data"
                for {
                    set reference = $query(@reference)
                    quit:reference=""
                    if $qsubscript(reference,3)="O" {
                        set args(@reference)=$qsubscript(reference,1)
                        if $Data(%request.Data($qsubscript(reference,1),$qsubscript(reference,2)),argValue)#2 && (argValue '= "") {
                            set args(@reference)=args(@reference)_"="_argValue
                        }
                    }
                }
                
                // Problem: args(1) might contain $c(10) followed by our stdin value
                if $Data(args(1))#2 {
                    set stdin = $Piece(args(1),$c(10),2,*)
                    set args(1) = $Piece(args(1),$c(10))
                }

                set gitArgs($i(gitArgs)) = "color.ui=true"

                // TODO: Don't be lazy! Implement shlex.split in ObjectScript.
                // The below is just a little bit cheesy.
                set argList = $ListFromString(args(1)," ")
                set pointer = 0
                set inQuotedString = 0
                while $ListNext(argList,pointer,arg) {
                    set argStartsQuotedString = ($Extract(arg) = """")
                    set argEndsQuotedString = ($Extract(arg,*) = """")
                    if (inQuotedString) {
                        set inQuotedString = 'argEndsQuotedString
                        set gitArgs(gitArgs) = gitArgs(gitArgs)_" "_$Extract(arg,1,*-argEndsQuotedString)
                    } elseif (arg '= "") {
                        set gitArgs($i(gitArgs)) = $Extract(arg,1+argStartsQuotedString,*-argEndsQuotedString)
                        set inQuotedString = argStartsQuotedString && 'argEndsQuotedString
                    }
                }

                // Do we have stdin?
                if (stdin '= "") {
                    set inStream = ##class(%Stream.FileCharacter).%New()
                    set inLines = $ListFromString(stdin,$c(10))
                    set pointer = 0
                    while $ListNext(inLines,pointer,line) {
                        do inStream.WriteLine(line)
                    }
                    $$$ThrowOnError(inStream.%Save())
                    set inFile = inStream.Filename
                    set inStream.RemoveOnClose = 1
                } else {
                    set inFile = ""
                }
                set returnCode = ##class(SourceControl.Git.Utils).RunGitCommandWithInput("-c",inFile,.errStream,.%data,gitArgs...)

                do %data.MoveToEnd()

                while 'errStream.AtEnd {
                    do %data.WriteLine(errStream.ReadLine())
                }
                
                // Need to write out two lines or we get an infinite loop in JavaScript...
                do %data.WriteLine()
                do %data.WriteLine()
                do %data.WriteLine("Git-Stderr-Length: " _ errStream.Size)
                do %data.Write("Git-Return-Code: " _ returnCode) // No ending newline expected
                do %data.Rewind()
                set handled = 1
            }
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

