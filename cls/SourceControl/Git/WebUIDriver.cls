Class SourceControl.Git.WebUIDriver
{

ClassMethod HandleRequest(pagePath As %String, InternalName As %String = "", Output handled As %Boolean = 0, Output %data As %Stream.Object)
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    kill %data
    #dim %response as %CSP.Response
    #dim %request as %CSP.Request
    set pathStart = $piece(pagePath,"/",2)
    if pathStart = "api" {
        do %session.Unlock()
        set handled = 1
        set %data = ##class(%Stream.FileCharacter).%New()
        if $extract(pagePath,6,*) = "userinfo" {
            set responseJSON = ..UserInfo()
        } elseif $extract(pagePath,6,*) = "uncommitted" {
            set responseJSON = ..Uncommitted()
        } elseif $extract(pagePath,6,*) = "settings" {
            set responseJSON = ..GetSettingsURL(%request)
        } elseif $extract(pagePath, 6, *) = "get-package-version"{
            set responseJSON = ..GetPackageVersion()
        } elseif $extract(pagePath, 6, *) = "git-version" {
            set responseJSON = ..GetGitVersion()
        } elseif $extract(pagePath,6,*) = "home"{
            set responseJSON = {
                "url": (..GetHomeURL())
            }
        } elseif $extract(pagePath,6,*) = "remote" {
            set responseJSON = ..GetRemote()   
        } elseif $extract(pagePath,6,*) = "environment" {
            set responseJSON = {
                "environment": (##class(SourceControl.Git.Utils).EnvironmentName()) 
            }
        } elseif $extract(pagePath, 6, *) = "basic-and-default" {
            set responseJSON = {
                "basic-and-default": (##class(SourceControl.Git.Utils).InDefaultBranchBasicMode())
            }    
        } else {
            set %response.Status = ##class(%CSP.REST).#HTTP404NOTFOUND
            set responseJSON = {"error":("invalid URI: " _ pagePath)}
        }
        if $isobject($get(responseJSON)) {
            do responseJSON.%ToJSON(%data)
        }
    } elseif pathStart = "vscode-workspace" {
        set handled = 1
        set namespace = $Namespace
        set instanceName = $ZConvert(##class(%SYS.System).InstanceGUID(),"L")
        set hasCSP = 0
        if context.IsInGitEnabledPackage && 'context.IsInDefaultPackage {
            set workspaceFilename = context.Package.Name_"-"_instanceName_".code-workspace"
            // Loading an IPM package in dev mode automatically creates a project for it, so filter to that.
            set filter = "?project="_context.Package.Name
        } else {
            set hasCSP = ##class(SourceControl.Git.Settings).HasNamespaceWebApp()
            set workspaceFilename = namespace_"-"_instanceName_".code-workspace"
            set filter = "?mapped=0"
        }
        set server = {
            "webServer": {
                "host": (%request.CgiEnvs("SERVER_NAME")),
                "port": (+%request.CgiEnvs("SERVER_PORT")),
                "scheme": ($Select(%request.Secure:"https",1:"http"))
            },
            "username": ($Username)
        }
        if (%request.URLPrefix '= "") {
            set server.webServer.pathPrefix = %request.URLPrefix
        }
        set workspaceDef = {
            "folders": [
            ],
            "settings": {
                "intersystems.servers": {
                    "/default": (instanceName)
                },
                "objectscript.conn": {
                    "active": false
                }
            }
        }
        if hasCSP {
            do workspaceDef.folders.%Push({
                "name": ($Namespace),
                "uri": ("isfs://"_instanceName_":"_$Namespace_"/git/"_$Namespace_"?csp")
            })
        } else {
            do workspaceDef.folders.%Push({
                "name": ($Namespace),
                "uri": ("isfs://"_instanceName_":"_$Namespace_"/"_filter)
            })
        }
        set $Property(workspaceDef.settings."intersystems.servers",instanceName) = server
        set stream = ##class(%CSP.CharacterStream).%New()
        do stream.SetAttribute("ContentDisposition","attachment; filename="_workspaceFilename)
        set formatter = ##class(%JSON.Formatter).%New()
        do formatter.FormatToStream(workspaceDef,stream)
        $$$ThrowOnError(stream.%Save())
        do %request.Set("STREAMOID",##class(%CSP.Page).Encrypt(stream.%Oid()))
        set %request.Data("EXPIRES",1,"encrypt") = 1
        do %request.Set("EXPIRES",0)
        do ##class(%CSP.StreamServer).OnPreHTTP() // Need to call this to set headers properly
        set %stream = 1 // Leak this to webuidriver.csp
    } elseif $match(pathStart,"git-command|git|dirname|hostname|viewonly|discarded-states|restore-discarded|contexts|create-branch|git-command-unstage") {
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
                do %session.Unlock()
                if $piece(pagePath,"/",3) = "cat-file" {
                    set blob = $piece(pagePath,"/",4)
                    set name = $Piece(pagePath,"/",*)
                    do ##class(SourceControl.Git.Utils).RunGitCommand("-c",,.rawData,"color.ui=false","cat-file","-p",blob)
                    // TODO: Support binary file types properly. This will need some deeper client-side changes.
                    /*
                    do ##class(%CSP.StreamServer).FileClassify($Piece(name,".",*),.type,.bin,.charset)
                    set %response.ContentType = type
                    if ($Get(charset) = "") {
                        set %response.NoCharSetConvert = 1
                    }
                    if bin {
                        set %data = rawData
                    } else {
                    */
                    // Render HTML stream in a <pre> with text file contents HTML-escaped.
                    set %data = ##class(%Stream.TmpBinary).%New()
                    do %data.Write("<html><body><pre>")
                    do rawData.Rewind()
                    while 'rawData.AtEnd {
                        do %data.Write($ZConvert(rawData.Read(),"O","HTML"))
                    }
                    do %data.Write("</pre></body></html>")
                    //}
                    set handled = 1
                }
            } elseif (pathStart = "hostname") {
                do %data.Write(##class(%SYS.System).GetNodeName())
                set handled = 1
            } elseif (pathStart = "viewonly") {
                // Never view-only
                do %data.Write(0)
                set handled = 1
            } elseif (pathStart = "dirname") {
                do %data.Write(##class(SourceControl.Git.Utils).TempFolder())
                set handled = 1
            } elseif (pathStart = "discarded-states") {
                set discardsInBranch = ##class(SourceControl.Git.DiscardState).DiscardStatesInBranch()
                do discardsInBranch.%ToJSON(%data)
                set handled = 1
            } elseif (pathStart = "contexts") {
                set onlyNamespaces = %request.Data("onlyNamespaces", 1)
                set contexts = ##class(SourceControl.Git.Utils).GetContexts(onlyNamespaces)
                do contexts.%ToJSON(%data)
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
                merge data = %request.Data 
                set args = data("command",1)
                
                // Problem: args(1) might contain $c(10) followed by our stdin value
                if $data(args)#2 {
                    set stdin = $piece(args,$char(10),2,*)
                    set args = $piece(args,$char(10))
                }
                set readOnlyCommands = $listbuild("branch","tag","log","ls-files","ls-tree","show","status","diff")
                set baseCommand = $Piece(args," ")
                
                if $listfind(readOnlyCommands,baseCommand) {
                    do %session.Unlock()
                }

                set gitArgs($increment(gitArgs)) = "color.ui=true"

                // TODO: Don't be lazy! Implement shlex.split in ObjectScript.
                // The below is just a little bit cheesy.
                set argList = $listfromstring(args," ")
                set pointer = 0
                set inQuotedString = 0
                while $listnext(argList,pointer,arg) {
                    set argStartsQuotedString = ($extract(arg) = """")
                    set argEndsQuotedString = ($extract(arg,*) = """")
                    if (inQuotedString) {
                        set inQuotedString = 'argEndsQuotedString
                        set gitArgs(gitArgs) = gitArgs(gitArgs)_" "_$extract(arg,1,*-argEndsQuotedString)
                    } elseif (arg '= "") {
                        set gitArgs($increment(gitArgs)) = $extract(arg,1+argStartsQuotedString,*-argEndsQuotedString)
                        set inQuotedString = argStartsQuotedString && 'argEndsQuotedString
                    }
                }

                // Do we have stdin?
                if (stdin '= "") {
                    set inStream = ##class(%Stream.FileCharacter).%New()
                    set inLines = $listfromstring(stdin,$char(10))
                    set pointer = 0
                    while $listnext(inLines,pointer,line) {
                        do inStream.WriteLine(line)
                    }
                    $$$ThrowOnError(inStream.%Save())
                    set inFile = inStream.Filename
                    set inStream.RemoveOnClose = 1
                } else {
                    set inFile = ""
                }

                set returnCode = ##class(SourceControl.Git.Utils).RunGitCommandWithInput("-c",inFile,.errStream,.outStream,gitArgs...)

                do ..ConvertGitOutput(.outStream,.errStream,returnCode,.%data)
                if '$listfind(readOnlyCommands,baseCommand) {
                    do ##class(SourceControl.Git.Change).RefreshUncommitted(,,,1)
                }
                set handled = 1
            } elseif (pathStart = "git-command") {
                do ..UnpackRequest(.%request, .requestBody)
                set command = requestBody.command

                set gitCmd = command.%Get(0)

                set discardedFiles = []
                if gitCmd = "restore" {
                    set iter = command.%GetIterator()
                    set isFile = 0
                    while iter.%GetNext(,.value) {
                        if isFile {
                            set internalName = ##class(SourceControl.Git.Utils).NameToInternalName(value)
                            do ##class(SourceControl.Git.DiscardState).SaveDiscardState(internalName, value)
                            if (internalName'="") {
                                set externalName = ##class(SourceControl.Git.Utils).FullExternalName(internalName)
                                $$$ThrowOnError(##class(SourceControl.Git.Change).RemoveUncommitted(externalName,0,1))
                                do discardedFiles.%Push(externalName)
                            }

                        }
                        if value = "--"{
                            set isFile = 1
                        }
                    }
                }
                $$$ThrowOnError(##class(SourceControl.Git.Change).RefreshUncommitted(0,1,,1))

                set argsArr = ""
                set argsArr($increment(argsArr)) = "color.ui=true"
                set iterator = command.%GetIterator()
                while iterator.%GetNext(,.value) {
                    set argsArr($increment(argsArr)) = value
                }

                set inFile = ""

                set returnCode = ##class(SourceControl.Git.Utils).RunGitCommandWithInput("-c", inFile, .errStream, .outStream, argsArr...)
                
                do ..ConvertGitOutput(.outStream,.errStream,returnCode,.%data)
                set handled = 1

                // Make sure discarded items are not in the uncommitted queue
                set item = discardedFiles.%Pop()
                while (item '= "") {
                    do ##class(SourceControl.Git.Change).RemoveUncommitted(item,0,1)
                    set item = discardedFiles.%Pop()
                }
                
            } elseif (pathStart = "restore-discarded") {
                merge data = %request.Data 
                set fileId = data("file",1)
                
                set %data = ##class(%Stream.TmpCharacter).%New()

                set discardState = ##class(SourceControl.Git.DiscardState).%OpenId(fileId)
                do ##class(SourceControl.Git.Change).RefreshUncommitted(,,,1)
                if ##class(SourceControl.Git.Change).IsUncommitted(discardState.FullExternalName) {
                    do %data.WriteLine("Please commit changes to file before restoring discarded state")
                } else {
                    do discardState.RestoreToFileTree()
                    do %data.WriteLine("Successfully restored discarded file state")
                }

                do %data.Rewind()
                do ##class(SourceControl.Git.Change).RefreshUncommitted(,,,1)
                set handled = 1  
            } elseif (pathStart = "create-branch") {
                set branchName = $get(%request.Data("branch",1),"")
                if (branchName = "") {
                    do %data.Write("ERROR! Enter a valid branch name")
                } else {
                    set %data = ##class(%Stream.TmpCharacter).%New()

                    set st =  ##class(SourceControl.Git.Utils).NewBranch(branchName)
                    if $$$ISERR(st) {
                        do %data.Write("Error! "_$System.Status.GetErrorText(st))
                    } else {
                        do %data.Write(branchName_" branch created!")
                    }
                    set handled = 1
                }
            } elseif (pathStart = "git-command-unstage") {
                do ..UnpackRequest(.%request, .requestBody)

                set flags = requestBody.flags
                if (flags '= "") {
                    set flaglist = $listfromstring(flags,",")
                    for i=1:1:$listlength(flaglist) {
                        set flag = $listget(flaglist,i)
                        set args($increment(args)) = flag
                    }
                }
                set message = requestBody.message
                if (message '= "") {
                    set args($increment(args)) = "-m"
                    set args($increment(args)) = message
                }
                set details = requestBody.details
                if (details '= "") {
                    set args($increment(args)) = "-m"
                    set args($increment(args)) = details
                }
                set command = requestBody.command
                
                // Extract Files
                set fileList = []
                set files = requestBody.files
                set iter = files.%GetIterator()
                    while iter.%GetNext(,.value) {
                        do fileList.%Push(value)
                    }

                set returnCode = ##class(SourceControl.Git.Utils).RunGitCommandReStage(.outStream,.errStream,command,.fileList,args...)

                do ..ConvertGitOutput(.outStream,.errStream,returnCode,.%data)
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
    do ##class(SourceControl.Git.Change).RefreshUncommitted()
    do ##class(SourceControl.Git.Utils).GitStatus(.files, 1)
    set output = ""
    set key = ""

    set editedByCurrentUser = []
    set fileToOtherDevelopers = {}
    for {
        set key = $order(files(key),1,fileData)
        quit:key=""
        // Check that current user has files(key) uncommitted and only %Push if they do
        set filename = ##class(Utils).FullExternalName(key)
        if (($ISVALIDNUM(key)) && (files(key) '= "")){
            do editedByCurrentUser.%Push($listget(fileData,2))
        }
        else{
            set sc=##class(SourceControl.Git.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
            if ($$$ISOK(sc)) && ($data(tAction)&&(UncommittedUser=$username)) {
                do editedByCurrentUser.%Push($listget(fileData,2))
            }
        }
    }

    do fileToOtherDevelopers.%Set("current user's changes", editedByCurrentUser)
    do fileToOtherDevelopers.%Set("other users' changes", ##class(SourceControl.Git.Change).GetOtherDeveloperChanges())
    quit fileToOtherDevelopers
}

ClassMethod UncommittedWithAction() As %SystemBase
{
    set uncomittedWithAction = ##class(SourceControl.Git.Utils).UncommittedWithAction()
    quit uncomittedWithAction
}

ClassMethod GetURLPrefix(%request As %CSP.Request, URL As %String) As %String
{
    set appBasePath = "/isc/studio/usertemplates/gitsourcecontrol/"
    set locationOfAppPath = $LOCATE(%request.URL, appBasePath)

    if (locationOfAppPath > 1) {
        set beforeAppPath = $EXTRACT(%request.URL, 1, (locationOfAppPath-1))
        set URL = beforeAppPath_URL
    }
    quit URL
}

ClassMethod GetSettingsURL(%request As %CSP.Request) As %SystemBase
{
    set settingsURL = "/isc/studio/usertemplates/gitsourcecontrol/gitprojectsettings.csp?CSPSHARE=1&Namespace="_$namespace_"&Username="_$username
    set settingsURL = ..GetURLPrefix(%request, settingsURL)
    quit {"url": (settingsURL)}
}

ClassMethod GetPackageVersion() As %Library.DynamicObject
{
    set version = ##class(SourceControl.Git.Utils).GetPackageVersion()
    quit {"version": (version)}
}

ClassMethod GetGitVersion() As %Library.DynamicObject
{
    set gitExists = ##class(SourceControl.Git.Utils).GitBinExists(.version)
    set version = +$PIECE(version,"version ",2)
    quit {"version": (version)}
}

ClassMethod GetHomeURL() As %String
{
    set prefix = ""
    if $IsObject($Get(%request)) {
        set prefix = $Piece(%request.Application,%request.AppMatch)
    }
    quit prefix_"/csp/sys/UtilHome.csp?$NAMESPACE="_$namespace
}

ClassMethod GetRemote() As %Library.DynamicObject
{
    set remote = ##class(SourceControl.Git.Utils).GetRedactedRemote()
    quit {"remote": (remote)}
}

ClassMethod UnpackRequest(ByRef %request As %CSP.Request, Output obj As %Library.DynamicObject) As %Status
{
    set stringBody = ""
    while '%request.Content.AtEnd {
        set stringBody = stringBody _ %request.Content.Read()
    }
    set stringBody = $zconvert(stringBody,"I","UTF8")
    set obj = ##class(%Library.DynamicObject).%FromJSON(stringBody)
    return $$$OK
}

ClassMethod ConvertGitOutput(ByRef outStream, ByRef errStream, returnCode As %String, Output %data) As %Status
{
    set %data = ##class(%Stream.TmpCharacter).%New()
    set changeTerminators = (%data.LineTerminator '= $char(13,10))
    set %data.LineTerminator = $char(13,10) // For the CSPGateway.
    while 'outStream.AtEnd {
        do %data.WriteLine(outStream.ReadLine())
    }

    set nLines = 0
    while 'errStream.AtEnd {
        do %data.WriteLine(errStream.ReadLine())
        set:changeTerminators nLines = nLines + 1
    }

    do %data.WriteLine("Git-Stderr-Length: " _ (errStream.Size + nLines))
    do %data.Write("Git-Return-Code: " _ returnCode) // No ending newline expected
    do %data.Rewind()
    return $$$OK
}

}
