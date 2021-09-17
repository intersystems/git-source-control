Include (%occStatus, %occErrors, SourceControl.Git)

Class SourceControl.Git.Utils [ Abstract, ProcedureBlock ]
{

Parameter Storage = "^SYS(""SourceControl"",""Git"")";

Parameter InstallNamespace = "%SYS";

Parameter Slash = {$case($system.Version.GetOS(),"Windows":"\",:"/")};

/// Name of the file with version controlled items
Parameter SCListFilename = "sc-list.txt";

Parameter GitMenuItems = ",%Settings,%Commit,%Pull,%Fetch,%Switch,%Merge,%Push,%Diff,%RepoStatus,%Resolve,%Revert,%Log,%StashSave,%StashPop,";

Parameter ImportAfterGitMenuItems = ",%Clone,%Commit,%Pull,%Fetch,%Push,%Resolve,%StashPop,";

Parameter GitContextMenuItems = ",%Diff,%Blame,";

ClassMethod InstallNamespaceStorage() As %String [ CodeMode = expression ]
{
$Replace(..#Storage,"^","^["""_..#InstallNamespace_"""]")
}

/// Returns root temp folder
ClassMethod DefaultTemp() As %String [ CodeMode = expression ]
{
$Get(@..InstallNamespaceStorage()@("%defaultTemp"), "c:\temp\")
}

// 8012 because this error has corresponding error message

ClassMethod MakeError(msg As %String) As %Status [ CodeMode = expression, Private ]
{
$$$ERROR(8012,"Git",msg)
}

ClassMethod TempFolder() As %String [ CodeMode = expression ]
{
$Get(@..#Storage@("settings","namespaceTemp"),..DefaultTemp()_$Translate($znspace,"%")_..#Slash)
}

ClassMethod GroupByFolder() As %String [ CodeMode = expression ]
{
$Get(@..#Storage@("settings","groupByFolder"), 0)
}

ClassMethod MappingsNode() As %String [ CodeMode = expression ]
{
$Name(@..#Storage@("settings","mappings"))
}

ClassMethod GitBinExists() As %Boolean
{
	#if $system.Version.GetOS()'="Windows" 
	 quit 0
	#else 
	if '$Data(@..InstallNamespaceStorage()@("%gitBinExists")) {
		set @..InstallNamespaceStorage()@("%gitBinExists") = ##class(%File).Exists($Extract(..GitBinPath(),2,*-1))
	}
	quit @..InstallNamespaceStorage()@("%gitBinExists")
	#endif
}

ClassMethod GitBinPath() As %String
{
    set binPath = $Get(@..InstallNamespaceStorage()@("%gitBinPath"))
    quit $case($Extract(binPath),"""":binPath,:""""_binPath_"""")
}

ClassMethod GitUserName() As %String
{
    Quit $Get(@..#Storage@("settings","user",$username,"gitUserName"))
}

ClassMethod GitUserEmail() As %String
{
    Quit $Get(@..#Storage@("settings","user",$username,"gitUserEmail"))
}

ClassMethod NeedSettings() As %Boolean [ CodeMode = expression ]
{
(..DefaultTemp() = "") ||  (..GitBinPath() = "") ||  (..GitBinPath() = """")
}

ClassMethod InstallNamespace() As %String [ CodeMode = expression ]
{
..#InstallNamespace
}

ClassMethod AddSlash(path As %String) As %String [ Private ]
{
	if path'="" && ($Extract(path,*)'=..#Slash) {
        set path = path_..#Slash
    }
    quit path
}

ClassMethod UpdateSettings(ByRef settings) As %Status
{
    // we change ^STORAGE to ^["InstallNamespace"]|STORAGE, so we store path to git.exe in one place
    set @..InstallNamespaceStorage()@("%gitBinPath") = settings("gitBinPath")
    kill @..InstallNamespaceStorage()@("%gitBinExists")
    
    // let's add slash in the end
    set @..InstallNamespaceStorage()@("%defaultTemp") = ..AddSlash(settings("defaultTemp"))
    
    set @..#Storage@("settings","namespaceTemp") = ..AddSlash(settings("namespaceTemp"))
    set @..#Storage@("settings","groupByFolder") = $case(settings("groupByFolder"), "":"", :1)
    set @..#Storage@("settings","user",$username,"gitUserName") = settings("gitUserName")
    set @..#Storage@("settings","user",$username,"gitUserEmail") = settings("gitUserEmail")
    
    quit $$$OK
}

ClassMethod GitCommand(commandName As %String, itemName As %String = "") As %String [ CodeMode = expression ]
{
..GitBinPath()_" /command:"_commandName_
               " /path:"""_..TempFolder()_
               $case(itemName,"":"",:..ExternalName(itemName))_""""_
               $case(commandName,"clone":" /exactpath:"_..TempFolder(),:"")
}

ClassMethod IsMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$Find(..#GitMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsContextMenuGitCommand(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$Find(..#GitContextMenuItems, ","_menuItemName_",") > 0
}

ClassMethod IsImportAfter(menuItemName As %String) As %Boolean [ CodeMode = expression ]
{
$Find(..#ImportAfterGitMenuItems, ","_menuItemName_",") > 0
}

ClassMethod UserAction(InternalName As %String, MenuName As %String, ByRef Target As %String, ByRef Action As %String, ByRef Reload As %Boolean) As %Status
{
	#define Force 1
    #dim menuName As %String = $Piece(MenuName,",")
    #dim menuItemName As %String = $Piece(MenuName,",",2)
    #dim ec As %Status = $$$OK
    
    if ..GitBinExists() = 0 && (menuItemName'="%Cache-Git-Settings") && 
    		($system.Version.GetOS()="Windows") {
        write !!,"===Path to tortoisegitproc.exe not found: "_..GitBinPath()_"!===",!
    }
    // this is here to test git fetch
    
    if (menuName = "%SourceMenu") {
        if (menuItemName = "%Cache-Git-Settings") {
            set Action = 2
            set Target = "/isc/studio/usertemplates/gitprojectsettings.csp?NSpace="_$namespace_"&Username="_$username
        }elseif (menuItemName = "%CreateRepo") {
            if ##class(%File).CreateDirectoryChain(..TempFolder()) {
                // cleanup items info
                kill @..#Storage@("items")
                kill @..#Storage@("TSH")
                set Action = 3
                set Target = ..GitCommand("repocreate")
            } else {
                set ec = ..MakeError("Unable to create folder "_..TempFolder())
            }
        } elseif (menuItemName = "%GitWebUI") {
            set Action = 2
            set Target = "/isc/studio/usertemplates/webuidriver.csp/"_$namespace
        }elseif (menuItemName = "%Export") || (menuItemName = "%ExportForce") {
            write "==export start==",!
            set ec = ..ExportAll($case(menuItemName="%ExportForce",1:$$$Force,:0))
            if ec {
                write !,"==export done==",!
            }
        }elseif (menuItemName = "%Import") {
            set ec = ..ImportAll()
            set Reload = 1
        }elseif (menuItemName = "%ImportForce") {
            set ec = ..ImportAll($$$Force)
            set Reload = 1
        }elseif (menuItemName = "%Clone") {
            if ##class(%File).CreateDirectoryChain(..TempFolder()) {
                // cleanup items info
                kill @..#Storage@("items")
                kill @..#Storage@("TSH")
                set Action = 3
                set Target = ..GitCommand("clone", "")
            } else {
                set ec = ..MakeError("Unable to create folder "_..TempFolder())
            }
        }elseif (menuItemName = "%OpenRepoFolder") {
	        set Action = 3
	        set Target = ..TempFolder()
    	}elseif (menuItemName = "%Revert") {
	    	set Reload = 1
	    	quit ..Revert(InternalName)
	    }elseif (menuItemName = "%Commit") {
	    	set Target = "Please enter a commit message"
	    	set Action = 7
	    	quit ..Commit(InternalName)
	    }elseif (menuItemName = "%Push") {
	    	quit ..Push()
	    	//, Studio still crashes when calling rungitcommand with push as command
	    	//quit $$$OK
	    }elseif (menuItemName = "%Fetch") {
            //TODO: Implement fetch git command
            $$$QuitOnError(..Fetch(.diffFiles))
            set pointer = 0
            while $ListNext(diffFiles, pointer, item){
	        	w item
	        }
	    }elseif (menuItemName = "%Pull") {
		    //TODO: Implement pull git command
            quit $$$OK
	    }
    	elseif ..IsMenuGitCommand(menuItemName) {
                set Action = 3
                #dim command As %String = $ZConvert($Extract(menuItemName, 2, *), "L")
                set ec = $$$OK
                if $Data(@..#Storage@("settings","hook"),hook)=1 {
	                set $ListBuild(class,method) = hook
	                set ec = $classmethod(class, method, command, InternalName)
                }
                if $$$ISOK(ec) {
                	set Target = ..GitCommand(command)
                }
        }
    }elseif (menuName = "%SourceMenuContext") {
	    
	    if (..Type(InternalName) = "csp") && ($Extract(InternalName,1) '= "/") {
	        set InternalName = "/" _ InternalName
        }
        
        if (menuItemName = "%AddToSC") {
            set ec = ..AddToSourceControl(InternalName)
        }elseif (menuItemName = "%RemoveFromSC") {
            set ec = ..RemoveFromSourceControl(InternalName)
        }
        if ..IsContextMenuGitCommand(menuItemName) {
            set Action = 3
            set command = $ZConvert($Extract(menuItemName, 2, *), "L")
            set Target = ..GitCommand(command, InternalName)
        }
    }
    if ..IsImportAfter(menuItemName) && (Action = 3) {
	    write "Choose Import All menu after work with Git!", !
    }
    //w Target,!
    quit ec
}

ClassMethod AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
    quit $$$OK
}

ClassMethod Revert(InternalName As %String) As %Status
{
	set filename = ..FullExternalName(InternalName)
	do ..RunGitCommand("checkout", .errStream, .outStream, "--", filename)
	$$$QuitOnError(##class(SourceControl.Git.Change).RemoveUncommitted(filename,0,1))
	$$$QuitOnError(##class(SourceControl.Git.Change).RefreshUncommitted(0,1))
	$$$QuitOnError(..ImportItem(InternalName))
	quit $$$OK
}

ClassMethod Commit(InternalName As %String, Message As %String = "example commit message") As %Status
{
	set filename = ..FullExternalName(InternalName)
	set username = """"_..GitUserName()_""""
	set email = """"_..GitUserEmail()_""""
	do ..RunGitCommand("config", .errStream, .outStream, "user.name", username)
	do ..RunGitCommand("config", .errStream, .outStream, "user.email", email)
	do ..RunGitCommand("commit", .errStream, .outStream, "-m", Message, filename)
	quit $$$OK
}

ClassMethod Push() As %Status
{
	do ..RunGitCommand("push", .errStream, .outStream)
	w "git push"
	do errStream.OutputToDevice()
	do outStream.OutputToDevice()
	quit $$$OK
}

ClassMethod Fetch(ByRef diffFiles) As %Status
{
	do ..RunGitCommand("fetch", .errStream, .outStream)
	w !, "git fetch"
	//git diff ..origin --name-only
	//another test for push
	kill errStream, outStream
	do ..RunGitCommand("diff", .errStream, .outStream, "..origin", "--name-only")
	set diffFiles = ""
    while (outStream.AtEnd = 0) {
        set diffFiles = diffFiles_$lb(outStream.ReadLine())
    }
	quit $$$OK
}

ClassMethod Pull() As %Status
{
	quit $$$OK
}

ClassMethod ConfigureGitAuthentication(Username As %String, Password As %String)
{
	//git config credential.helper store
	//write !,"git config --system credential.helper manager"
	//git config credential.helper '!f() { printf "%s\n" "username=$USER" "password=$PASS"; };f'
	do ..RunGitCommand("config", .errStream, .outStream, "--global", "credential.helper", "store")
	do errStream.OutputToDevice()
	do outStream.OutputToDevice()
	/*
	write !,"git config --global credential.modalPrompt false"
	do ..RunGitCommand("config", .errStream, .outStream, "--global","credential.modalPrompt", "false")
	do errStream.OutputToDevice()
	do outStream.OutputToDevice()
	*/
	/*
	set file = ##class(%Stream.FileCharacter).%New()
	do file.WriteLine(Username)
	do file.WriteLine(Password)
	$$$ThrowOnError(file.%Save())
	set file.RemoveOnClose = 1
	*/
	write !,"git fetch"
	do ..RunGitCommand("fetch", .errStream, .outStream)
	do errStream.OutputToDevice()
	do outStream.OutputToDevice()
}

ClassMethod IsNamespaceInGit() As %Boolean [ CodeMode = expression ]
{
##class(%File).Exists(..TempFolder()_".git")
}

/// replaces any slashes with the ones for current OS<br/>
/// removes first slash if present<br/>
/// adds last slash if not present<br/>
ClassMethod NormalizeFolder(folder As %String) As %String
{
	set folder = $Translate(folder, "/", ..#Slash)
	set:$Extract(folder)=..#Slash $Extract(folder) = ""
	set:$Extract(folder,*)'=..#Slash folder = folder _ ..#Slash
	quit folder
}

ClassMethod ExternalName(InternalName As %String) As %String
{
	Quit ..Name(InternalName)
}

ClassMethod AddToSourceControl(InternalName As %String) As %Status
{
    #dim i As %Integer
    #dim ec As %Status = $$$OK
    for i = 1:1:$Length(InternalName, ",") {
        #dim item As %String = ..NormalizeExtension($Piece(InternalName, ",", i))
        set @..#Storage@("items", item) = ""
        #dim sc As %Status =  ..ExportItem(item)
        if 'sc {
            set ec = $$$ADDSC(ec, sc)
        }
    }
    set ec = $$$ADDSC(ec, ..ExportSCList())
    quit ec
}

ClassMethod DeleteExternalsForItem(InternalName As %String) As %Status
{
    #dim type As %String = ..Type(InternalName)
    #dim ec As %Status = $$$OK
    if (type = "prj") || (type = "pkg") || (type = "csp" && ..IsCspFolder(InternalName)) {
        // we delete complex items
        
        //get all item in files
        #dim itemsList
        $$$QuitOnError(..ListItemsInFiles(.itemsList))
        
        #dim item As %String = ""
        //for all item in files
        for  {
            set item = $Order(itemsList(item))
            quit:item=""
            
            //if item is not in sc -- delete file
            if '..IsInSourceControl(item) {
                #dim sc As %Status = ..DeleteExternalFile(item)
                if 'sc {
                    set ec = $$$ADDSC(ec, sc)
                }
            }
        }
    } else {
        set ec = ..DeleteExternalFile(InternalName)
    }
    quit ec
}

ClassMethod RemoveFromSourceControl(InternalName As %String) As %Status
{
    #dim sc As %Status = $$$OK
    for i = 1:1:$Length(InternalName, ",") {
	    #dim tsc As %Status = $$$OK
	    set item = $Piece(InternalName, ",", i)
	    if $Data(@..#Storage@("items", ..NormalizeExtension(item))) {
		    set item = ..NormalizeExtension(item)
	    }
	    
	    if $Data(@..#Storage@("items", item)) {
	        kill @..#Storage@("items", item)
	        set tsc = ..DeleteExternalsForItem(item)
	        do ..RemoveFolderIfEmpty(..TempFolder())
	        set tsc = $$$ADDSC(tsc, ..ExportSCList())
	    } else {
	        #dim parentElement As %String = ""
	        if ..IsInSourceControl(item, .parentElement) {
	            set tsc = ..MakeError(item _ " is contained in "_parentElement_" that tracked by SourceControl")
	        }else {
	            set tsc = ..MakeError(item _ " is not in SourceControl")
	        }
	    }
	    set sc = $$$ADDSC(tsc, sc)
    }

    quit sc
}

ClassMethod IsCspFolder(InternalName As %String) As %Boolean
{
    #dim extension = $Piece(InternalName, ".", $Length(InternalName, "."))
    quit:extension="csp" 0
    
    #dim filename = $system.CSP.GetFileName(InternalName_"/")
    if filename = "" && ($Extract(InternalName,1) '= "/") {
	    set filename = $system.CSP.GetFileName("/"_InternalName_"/")
    }
    quit filename'="" && ##class(%File).DirectoryExists(filename)
}

/// pkg -- package<br/>
/// prj -- project<br/>
/// csp -- csp-page or csp-folder. See <Method>IsCspFolder</Method><br/>
/// csp -- any static file from csp-folder 
ClassMethod Type(InternalName As %String) As %String
{
    #dim extension As %String = $ZConvert($Piece(InternalName,".",$Length(InternalName,".")),"L")
    #dim type As %String = extension
    
    if ($Extract(InternalName, 1, 4) = "/csp") 
          || ($Find(InternalName,".") = 0) 
          || ($Find(InternalName,"/") > 0) {
	          //we need to double-check
	          //Sometimes (see NormalizeInternalName) Studio passes routine names as /Package/SubPackage/Routine.mac
	          //Generally speaking this can be static file
	          if (type = "mac") || (type = "inc") || (type = "int") {
		          #dim filename = $system.CSP.GetFileName(InternalName)
		          if ##class(%File).Exists(filename) {
			          set type = "csp"
		          }
	          } else {
        			set type ="csp"
	          }
    }
   
    quit type
}

ClassMethod NameWithoutExtension(InternalName As %String) As %String [ CodeMode = expression ]
{
$Piece(InternalName, ".", 1, $Length(InternalName,".")-1)
}

/// packageName without extension
ClassMethod IsClassInPackage(ClassName As %String, packageName As %String) As %Boolean [ CodeMode = expression ]
{
$Extract(ClassName, 1, $Length(packageName)) = packageName
}

/// projectName without extension
ClassMethod IsItemInProject(InternalName As %String, projectName As %String) As %Boolean
{
    // we should check two cases
    // direct inclusion
    // inclusion in package or csp-folder that contained in project
    #dim type As %String = ..Type(InternalName)
    //w InternalName, "->"
    #dim name As %String = $case(type, "cls": ..NameWithoutExtension(InternalName), 
                                       "pkg": $Translate(..NameWithoutExtension(InternalName), "/", "."), 
                                       "csp": $Extract(InternalName, 2, *),
                                       :InternalName)
    if $Extract(name) = "." && (type = "pkg") {
        set $Extract(name) = ""
    }
    
    //w name, " "
    #dim checkId = projectName_"||"_name_"||"_$ZConvert(type,"U")
    //w checkId
    #dim isItemInProject As %Boolean = ##class(%Studio.ProjectItem).%ExistsId(checkId)
    //w " ", isItemInProject, !
    
    #dim i As %Integer
    if 'isItemInProject && ((type = "cls") || (type="pkg")) {
        for i = 1:1:$Length(name, ".") {
            set checkId = projectName_"||"_$Piece(name, ".", 1, i)_"||PKG"
            //w checkId, !
            if ##class(%Studio.ProjectItem).%ExistsId(checkId) {
                set isItemInProject = 1
                quit
            }
        }
    }
    
    if 'isItemInProject && (type = "csp") {
        for i = 1:1:$Length(name, "/") {
            set checkId = projectName_"||"_$Piece(name, "/", 1, i)_"||DIR"
            
            if ##class(%Studio.ProjectItem).%ExistsId(checkId) {
                set isItemInProject = 1
                quit
            }
        }
    }
    quit isItemInProject
}

ClassMethod IsItemInCSPFolder(InternalName As %String, cspFolder As %String) As %Boolean [ CodeMode = expression ]
{
$Extract(InternalName, 1, $Length(cspFolder)) = cspFolder
}

ClassMethod FindInPackages(InternalName As %String, ByRef sourceControlItem As %String) As %Boolean
{
    #dim item As %String = ""
    #dim found As %Boolean = 0
    for  {
        set item = $Order(@..#Storage@("items", item))
        quit:item=""
        continue:..Type(item)'="pkg"
        #dim packageName As %String = ..NameWithoutExtension(item)

        if ..IsClassInPackage(InternalName, packageName) {
            set found = 1
            set sourceControlItem = packageName
            quit
        }
    }
    quit found
}

ClassMethod FindInProjects(InternalName As %String, ByRef sourceControlItem As %String) As %Boolean
{
    #dim item As %String = ""
    #dim found As %Boolean = 0
    for  {
        set item = $Order(@..#Storage@("items", item))
        quit:item=""
        continue:..Type(item)'="prj"
        #dim projectName As %String = ..NameWithoutExtension(item)
        
        if ..IsItemInProject(InternalName, projectName) {
            set found = 1
            set sourceControlItem = projectName
            quit
        }
    }
    quit found
}

ClassMethod FindInCspFolders(InternalName As %String, ByRef sourceControlItem As %String) As %Boolean
{
    #dim cspFolder As %String = ""
    #dim found As %Boolean = 0
    for  {
        set cspFolder = $Order(@..#Storage@("items", cspFolder))
        quit:cspFolder=""
        //no need to check IsCspFolder. It might not exist yet
        //continue:'(..Type(cspFolder)="csp" && ..IsCspFolder(cspFolder))
        continue:'(..Type(cspFolder)="csp")


        
        if ..IsItemInCSPFolder(InternalName, cspFolder) {
            set found = 1
            set sourceControlItem = cspFolder
            quit 
        }
    }
    quit found
}

ClassMethod IsInSourceControl(InternalName As %String, ByRef sourceControlItem As %String) As %String
{
    #dim isInSourceControl As %Boolean = 1
    
    if $Data(@..#Storage@("items", ..NormalizeExtension(InternalName))) {
	    set InternalName = ..NormalizeExtension(InternalName)
    }
    
    set isInSourceControl = $Data(@..#Storage@("items", InternalName)) > 0
    if isInSourceControl {
        set sourceControlItem = InternalName
    }else {
        //if no direct reference maybe we have to look in packages, projects or csp-apps ?
        //We have three groups of routines
        //packages for classes
        //projects for everything
        //csp-folders for csp and static files

        #dim type As %String = ..Type(InternalName)
        if type = "cls" {
	        #define StripExtension(%s) $Piece(%s,".",1,$Length(%s, ".") - 1)
	        if InternalName'="" && ($$$defClassKeyGet($$$StripExtension(InternalName),$$$cCLASSgeneratedby)'="") {
		        set isInSourceControl = 0 // skip generated classes
	        } else {
            	set isInSourceControl = ..FindInPackages(InternalName, .sourceControlItem)
	        }
        } elseif type = "csp" {
	        if $Extract(InternalName) '= "/" {
		        set InternalName = "/" _ InternalName
	        }
            set isInSourceControl = ..FindInCspFolders(InternalName, .sourceControlItem)
        }
        
        // our last chance to find item -- let's look in projects
        if 'isInSourceControl {
            set isInSourceControl = ..FindInProjects(InternalName, .sourceControlItem)
        }
    }
    //w "checking ", $G(type), " ", InternalName, "=", isInSourceControl, !
    quit isInSourceControl
}

ClassMethod FullExternalName(InternalName As %String) As %String [ CodeMode = expression ]
{
##class(%File).NormalizeFilename(..TempFolder()_..ExternalName(InternalName))
}

ClassMethod NormalizeInternalName(name As %String) As %String
{
	//Studio passes name of routine with dots as it is in folders
	//e.g. Package.SubPackage.Routine.mac has InternalName =  /Package/SubPackage/Routine.mac
	//This happens if right-click in Workspace -> Namespace
	//If right-click in Workspace -> Project then everything passes ok
	//let's fix this
	if (name = "") {
		quit ""
	}
	
	if $Extract(name) '= "/" {
		quit $Piece(name,".",1,*-1)_"."_$ZConvert($Piece(name,".",*),"U")
	}
	
	set type = ..Type(name)
	
	if (type = "inc") || (type = "mac") || (type = "int") {
		set name = $Extract($Translate(name, "/", "."), 2, *)
	}
    quit name
}

ClassMethod NormalizeExtension(name As %String) As %String
{
    #dim extension = $Piece(name, ".", $Length(name, "."))
    if $Length(extension) <= 3 {
        set $Piece(name, ".", $Length(name, ".")) = $ZConvert(extension, "L")
    }
    quit name
}

ClassMethod RoutineTSH(InternalName As %String) As %String
{
    #dim type = ..Type(InternalName)
    //for csp-files (csp,js,html,css, all that stored in csp/...) we always check for changes in external file
    #dim tsh = $case(type,"csp":"",:$Get(@..#Storage@("TSH", ..NormalizeExtension(InternalName))))
    if tsh = "" {
        #dim ts As %String = ##class(%RoutineMgr).TS(InternalName)
        if ts '= "" {
            // prj files have milliseconds in timestamp, so we crop them
            set tsh = $Piece($ZDateTimeH(ts, 3),".",1)
        } else {
	        set tsh = "1840-12-31 00:00:00"
        }
    }
    quit tsh
}

ClassMethod UpdateRoutineTSH(InternalName As %String, tsh As %String) As %Status
{
    set @..#Storage@("TSH", ..NormalizeExtension(InternalName)) = $Get(tsh, $Horolog)
    quit $$$OK
}

ClassMethod RemoveRoutineTSH(InternalName As %String) As %Status
{
    kill @..#Storage@("TSH", ..NormalizeExtension(InternalName))
    quit $$$OK
}

ClassMethod DeleteExternalFile(InternalName As %String) As %Status
{
    #dim fullName = ##class(Utils).FullExternalName(InternalName)
    #dim ec As %Status = $$$OK
    if ##class(%File).Exists(fullName) {
        set ec = ##class(%File).Delete(fullName)
        do ..RemoveRoutineTSH(InternalName)
        write fullName, " for ", InternalName, " deleted",!
    }
    Quit ec
}

/// if temp file for InternalName not found return "0,0" in tempFileTSH
ClassMethod GetTempFileAndRoutineTS(InternalName As %String, ByRef tempFileTSH As %String, ByRef routineTSH As %String)
{
    #dim filename As %String = ..FullExternalName(InternalName)
    set tempFileTSH = ##class(%File).GetFileDateModified(filename)
    set routineTSH = ..RoutineTSH(InternalName)
    //file not found or path not found or some other error
    set:tempFileTSH<0 tempFileTSH = "0,0"
    set tempFileTSH = $zdatetime(tempFileTSH,3)
    set routineTSH = $zdatetime(routineTSH,3)
}

ClassMethod IsTempFileOutdated(InternalName As %String) As %Boolean
{
    do ..GetTempFileAndRoutineTS(InternalName,.tempFileTSH,.routineTSH)
    quit routineTSH]tempFileTSH
}

ClassMethod IsRoutineOutdated(InternalName As %String) As %Boolean
{
    do ..GetTempFileAndRoutineTS(InternalName,.tempFileTSH,.routineTSH)
    quit tempFileTSH]routineTSH
}

ClassMethod FixProjectCspReferences(projectName As %String) As %Status
{
    #dim loadedProject As %String = $Piece(projectName, ".", 1)
    // now we should fix reference to csp pages in project items
    // that is: if project was exported from USER and imported in SAMPLES
    // then all reference to csp/user/page.csp should be changed to csp/samples/page.csp
    #dim item As %String =""
    #dim oldCspApp As %String = ""
    #dim newCspApp As %String = ""
    for  {
        set item = $Order(^oddPROJECT(loadedProject,"Items",item))
        quit:item=""
        set type = $Order(^oddPROJECT(loadedProject,"Items",item,""))
        if type = "CSP" || (type = "DIR") {
            #dim newitem As %String = item
            set $Piece(newitem,"/",1,2) = $Extract($system.CSP.GetDefaultApp($znspace),2,*)
            if newitem '= item {
                set ^oddPROJECT(loadedProject,"Items",newitem,type) = ^oddPROJECT(loadedProject,"Items",item,type)
                kill ^oddPROJECT(loadedProject,"Items",item,type)
                set newCspApp = $Extract($system.CSP.GetDefaultApp($znspace),2,*)
                set oldCspApp = $Piece(item,"/",1,2)
            }
        }
    }
    quit $$$OK
}

/// imports file if version in system is newer then version on disk.
/// if <var>force</var> = 1 then imports in any case.
ClassMethod ImportItem(InternalName As %String, force As %Boolean = 0) As %Status
{
    //WRITE "Before Load Of: ", InternalName, " ", ..IsInSourceControl(InternalName), !
    //q:'..IsInSourceControl(InternalName) $$$OK
    #dim filename As %String = ..FullExternalName(InternalName)
    #dim fileTSH = ##class(%File).GetFileDateModified(filename)
    #dim sc As %Status = $$$OK
 
    if ..IsRoutineOutdated(InternalName) || force {
        set sc = $system.OBJ.Load(filename,"-l-d")
        if sc {
            set sc = ..UpdateRoutineTSH(InternalName, fileTSH)
            if ..Type(InternalName) = "prj" {
                set sc = $$$ADDSC(sc, ..FixProjectCspReferences(InternalName))
            }
            write InternalName," has been imported from ", filename,!
        } else {
	        write "ERROR importing" ,InternalName,!
	        do $system.Status.DisplayError(sc)
        }
    } else {
	    write InternalName, " is the same as on-disk version or newer, skipping import",!
    }
    Quit sc
}

ClassMethod ListItemsInFiles(ByRef itemList, ByRef err) As %Status
{
    #define DoNotLoad 1
    set res = $system.OBJ.ImportDir(..TempFolder(),"*.xml","-d",.err,1, .itemList, $$$DoNotLoad)
    
    if '$Data(itemList) && $$$ISERR(res) {
	    quit res
    }
    
    if $Get(err) > 0 {
	    write "There were some errors while importing files",!
	    for i=1:1:err {
		    write err(i),!
	    }
    }
    
    //change all csp/ names to /csp/ names
    #dim item As %String = "csp"
    for  {
        set item = $Order(itemList(item))
        quit:item=""
        quit:$Extract(item, 1, 4)'="csp/"
        kill itemList(item)
        set itemList("/"_item)=""
    }
    quit $$$OK
}

ClassMethod ImportRoutines(force As %Boolean = 0) As %Status
{
	write "==import start==", !
	
    #dim err, itemList
    
    kill err, itemList
    set err = 0   
    
    #dim ec As %Status = ..ListItemsInFiles(.itemList, .err)
    quit:'ec ec
    
    #dim internalName As %String = ""
    for  {
        set internalName = $Order(itemList(internalName))
        quit:internalName=""
        if '..IsInSourceControl(internalName) {
        	//w "item ",internalName," is not in source control, skipping",!
        	continue
        }
        #dim sc As %Status = ..ImportItem(internalName, force)
        if $$$ISERR(sc) {
            set ec = $$$ADDSC(ec, sc)
        }
    }
    
    //let's delete all items for which corresponding files had been deleted
    #dim item as %String = ""
    for  {
        set item = $Order(@..#Storage@("TSH", item))
        quit:item=""

        if '##class(%File).Exists(..FullExternalName(item)) {
            #dim type As %String = ..Type(item)
            #dim name As %String = ..NameWithoutExtension(item)
            #dim deleted As %Boolean = 1
            if type = "prj" {
                set ec = $$$ADDSC(ec, $system.OBJ.DeleteProject(name))
            }elseif type = "cls" {
                set ec = $$$ADDSC(ec, $system.OBJ.Delete(item))
            }elseif $ListFind($ListBuild("mac","int","inc","bas","mvb","mvi","dfi"), type) > 0 {
                set ec = $$$ADDSC(ec, ##class(%Routine).Delete(item))
            }elseif type = "csp" {
                #dim filename = $system.CSP.GetFileName(item)
                if ##class(%File).Exists(filename) && '##class(%File).Delete(filename) {
                    set ec = $$$ADDSC(ec, ..MakeError("Error while removing "_item))
                }
            } else {
                set deleted = 0
            }
            
            if deleted && ec {
                do ..RemoveRoutineTSH(item)
                write item, " was deleted", !
            } else {
	            if +$system.Status.GetErrorCodes(ec) '= $$$ClassDoesNotExist {
                	write "Error: could not delete ", item, !
	            } else {
		            // if something we wanted to delete is already deleted -- good!
		            set ec = $$$OK
	            }
            }
        }
    }
    
    write "==import done==", !
    quit ec
}

ClassMethod ExportRoutinesAux(path As %String, sep As %String = "", level As %Integer = 0, force As %Boolean = 0) As %Status
{
    #define Dir
    #define OrderBy
    #define SystemFiles
    #define Flat
    #define NotStudio
    #define ShowGenerated 0
    #define Filter
    #define CspFile 5
    #define Directory 9
    #define CSPFolder 10
    
    #dim rs As %ResultSet = ##class(%ResultSet).%New("%RoutineMgr:StudioOpenDialog")
    #dim ec As %Status = rs.Execute(path_$case(path,"":"",:"/")_"*",$$$Dir, $$$OrderBy, $$$SystemFiles, $$$Flat, $$$NotStudio, $$$ShowGenerated, $$$Filter)
    quit:'ec ec
    while rs.Next() {
        #dim name As %String = rs.Get("Name")
        #dim isdirectory As %String = rs.Get("IsDirectory")
        #dim type As %String = rs.Get("Type")
        
        if (type = $$$Directory) || (type = $$$CSPFolder) {
            #dim newpath As %String = $case(path,"":name,:path_isdirectory_name)
            do ..ExportRoutinesAux(newpath, isdirectory, level + 1, force)
        } else {
            #dim InternalName As %String = path_sep_name
            if (type = $$$CspFile) && ($Extract(InternalName) '= "/") {
                set InternalName = "/"_InternalName
            }
            set ec = ..ExportItem(InternalName, 1, force)
        }
    }
    kill rs
    quit ec
}

ClassMethod ExportItem(InternalName As %String, expand As %Boolean = 1, force As %Boolean = 0) As %Status
{
    #dim type = ..Type(InternalName)
    //write "checking if we should export "_InternalName,!
    if type = "pkg" {
        $$$QuitOnError(..ExportRoutinesAux(..NameWithoutExtension(InternalName), ".", 0, force))
    }elseif type = "prj" && expand {
        $$$QuitOnError(..ExportProject(..NameWithoutExtension(InternalName), force))
        $$$QuitOnError(..ExportItem(InternalName, 0, force))
    }elseif (type = "csp") && ..IsCspFolder(InternalName) {
        $$$QuitOnError(..ExportRoutinesAux(InternalName , "/", 0, force))
    }else {
        if ..IsTempFileOutdated(InternalName) || force {
            
            #dim filename As %String = ..FullExternalName(InternalName)
            write "exporting new version of ", InternalName, " to ", filename,!
            $$$QuitOnError($system.OBJ.ExportUDL(InternalName, filename,"-d/diff"))
            $$$QuitOnError(..UpdateRoutineTSH(InternalName, $Horolog))
        } else {
	        write !,InternalName, " is not newer than on-disk version, skipping export"
        }
    }
    quit $$$OK
}

ClassMethod ExportProject(project As %String, force As %Boolean = 0) As %Status
{
    #dim rs As %ResultSet = ##class(%ResultSet).%New("%Studio.Project:ProjectItemsList")
    $$$QuitOnError(rs.Execute(project))
    #dim typesWithoutExtension As %List = $ListBuild("CLS", "PKG")
    while rs.Next() {
        #dim name = rs.Get("Name")
        if $ListFind(typesWithoutExtension, rs.Get("Type")) {
            set name = name _ "." _ rs.Get("Type")
        }
        #dim ec As %Status = ..ExportItem(name, 1, force)
        quit:'ec
    }
    kill rs
    quit $$$OK
}

/// if <var>force</var> = 1 then we export item even if timestamp in system is older
ClassMethod ExportAll(force As %Boolean = 0) As %Status
{
    $$$QuitOnError(..ExportRoutines(force))
    quit ..ExportSCList()
}

/// if <var>force</var> = 1 then we import item even if timestamp in system is newer
ClassMethod ImportAll(force As %Boolean = 0) As %Status
{
    $$$QuitOnError(..ImportSCList())
    quit ..ImportRoutines(force)
}

ClassMethod ExportRoutines(force As %Boolean = 0) As %Status
{
    #dim item As %String = ""
    #dim ec As %Status = $$$OK
    for  {
        set item = $Order(@..#Storage@("items",item))
        quit:item=""
        set ec = ..ExportItem(item, 1, force)
        quit:'ec       
    }
    quit ec
}

ClassMethod ExportSCList() As %Status
{
    #dim filename = ..TempFolder()_..#SCListFilename    
    #dim file As %File = ##class(%File).%New(filename)
    #dim item As %String = ""
    #dim defaultCspApp As %String = $system.CSP.GetDefaultApp($znspace)
    $$$QuitOnError(file.Open("WSN"))
    
    for  {
        set item = $Order(@..#Storage@("items",item))
        quit:item=""
        #dim fixedItem As %String = item
        if $Extract(fixedItem, 1, $Length(defaultCspApp)) = defaultCspApp {
            set $Extract(fixedItem, 1, $Length(defaultCspApp)) = "<cspapp>"
        }
        
        do file.WriteLine(fixedItem)
        
    }
    $$$QuitOnError(file.%Save())
    do file.Close()
    kill file
    quit $$$OK
}

ClassMethod ImportSCList() As %Status
{
    #dim filename = ..TempFolder()_..#SCListFilename
    #dim file As %File = ##class(%File).%New(filename)
    #dim defaultCspApp As %String = $system.CSP.GetDefaultApp($znspace)
    #dim eol As %Boolean
    
    $$$QuitOnError(file.Open("R", 10))
    
    #dim a 
    while 'file.AtEnd  {
        #dim s As %String = file.ReadLine(,,.eol)
        continue:s=""
        #dim item As %String = $Replace(s, "<cspapp>", defaultCspApp)
        set a(..NormalizeExtension(item)) = ""
    }
    kill @..#Storage("items")
    merge @..#Storage("items") = a
    do file.Close()
    kill file
    quit $$$OK
}

/// returns true if directory was deleted
ClassMethod RemoveFolderIfEmpty(path As %String) As %Boolean
{
    #dim rs As %ResultSet = ##class(%ResultSet).%New("%File:FileSet")
    #define DirsFirst 1
    $$$QuitOnError(rs.Execute(path,,,$$$DirsFirst))
    #dim fileCount As %Integer = 0
    while rs.Next() {
        #dim fullname As %String = rs.Get("Name")
        #dim type As %String = rs.Get("Type")
        #dim name As %String = rs.Get("ItemName")
        #define IsDirectory(%type) %type="D"
        
        set fileCount = fileCount + 1
        quit:'$$$IsDirectory(type)
        continue:name=".git"
        if ..RemoveFolderIfEmpty(fullname) {
            set fileCount = fileCount - 1
        }
    }
    if fileCount = 0 {
        do ##class(%File).RemoveDirectory(path)
    }
    kill rs
    quit 'fileCount
}

ClassMethod RunGitCommand(command As %String, Output errStream, Output outStream, args...)
{
    do ..RunGitCommandWithInput(command,,.errStream,.outStream,args...)
}

ClassMethod RunGitCommandWithInput(command As %String, inFile As %String = "", Output errStream, Output outStream, args...)
{
	set newArgs($i(newArgs)) = "-C"
    set newArgs($i(newArgs)) = ..TempFolder()
    set newArgs($i(newArgs)) = command
    for i=1:1:$g(args) 
    {
        set newArgs($i(newArgs)) = args(i)
    }
    //trying to fix issue where different git commands write to same file
    //this is a dummy line to test push function
    set outLog = """"_command_"out.log"""
    set errLog = """"_command_"err.log"""
    set outLog1 = command_"out.log"
    set errLog1 = command_"err.log"
    do $zf(-100,"/STDOUT="_outLog_" /STDERR="_errLog_$Case(inFile, "":"", :" /STDIN="_inFile),"git",newArgs...)
    set outStream = ##class(%Stream.FileCharacter).%OpenId(##class(%File).NormalizeFilename(outLog1))
    set errStream = ##class(%Stream.FileCharacter).%OpenId(##class(%File).NormalizeFilename(errLog1))
}

ClassMethod GitStatus(ByRef files)
{
	do ..RunGitCommand("status", .errStream, .outStream, "-z", "-uall")
	set lines = outStream.ReadLine()
	set list = $ListFromString(lines, $c(0))
	set pointer = 0
	while $ListNext(list, pointer, item) {
		set operation = $Extract(item, 1, 2)
		set externalName = $Extract(item, 4, *)
		///w externalName_" "
		set internalName = ..NameToInternalName(externalName)
		///write internalName, !
		if (internalName '= "") {
			set files(internalName) = $lb(operation, externalName)
		}
	}
}

/*
    Internal name: e.g. SourceControl.Git.Utils.CLS
    External name e.g. cls/SourceControl/Git/Utils.cls
	Name(InternalName): returns Unix-style slash path relative to repo root cooresponding to internal name 
	(e.g., cls/SourceControl/Git/Utils.cls)
*/
ClassMethod Name(InternalName As %String) As %String
{
	Set InternalName=##class(%Studio.SourceControl.Interface).normalizeName(InternalName)
	Set usertype=$system.CLS.IsMthd("%Library.RoutineMgr","UserType")
		
	// For an abstract document, use the GetOther() method to try to determine its "real" class
	If usertype,##class(%RoutineMgr).UserType(InternalName,.docclass,.doctype) {
		// Check for a real abstract document subclass (or GetOther() may not work)
		If $classmethod(docclass,"%IsA","%Studio.AbstractDocument") {
			// Grab the actual name
			Set actualName = $classmethod(docclass,"GetOther",InternalName)
			// The actualName is only valid if we get a single .cls as a result
			If actualName'[",",$ZCVT($P(actualName,".",$L(actualName,".")),"U")="CLS" {
				// We use what GetOther() gives us, thus Demo.Loan.FindRateProcess.bpl becomes Demo.Loan.FindRateProcess.cls
				Set InternalName = actualName
			}
		}
	}	
	
	If $$CheckProtect^%qccServer(InternalName) Quit ""
	Set nam=$p(InternalName,".",1,*-1),ext=$p(InternalName,".",*),ext=$zcvt(ext,"u")
	If nam=""||(ext="") Quit ""
	// Any CSP items should be matched against the "/CSP/" mapping in ^Sources
	If InternalName["/" {
		Set filename=$$GetFilename^%apiCSP(InternalName)
		//Find if this csp file is located within the ^Sources tree, and return appropriate value
		If $$$isWINDOWS {
			If $zcvt($extract(filename,1,$length($$$SourceRoot)),"l")=$zcvt($$$SourceRoot,"l") Quit $extract(filename,$length($$$SourceRoot)+1,*)
		} Else {
			If $extract(filename,1,$length($$$SourceRoot))=$$$SourceRoot Quit $extract(filename,$length($$$SourceRoot)+1,*)
		}
		//Do not support manipulating files in the /itemsetsourcelink* csp app which are not inside of the namespace's ^Sources tree
		If InternalName["itemsetsourcelink" {
			Write !,"To control files in the /itemsetsourcelink* web app, they must be in this tree: "_$$$SourceRoot_" ("_InternalName_" is located at "_filename_")"
			Quit ""
		}
		// Any CSP items should be matched against the "/CSP/" mapping if the file is not stored in the ^Sources tree
		Set ext="/CSP/"	
	}
	If ext="PRJ",nam["Default_" Quit ""
	If ext="CLS",$$$defClassKeyGet(nam,$$$cCLASSgeneratedby)'="" Quit ""
	Set default=0
	Set p=$order($$$SourceMapping(ext,nam)) For  Set p=$order($$$SourceMapping(ext,p),-1) Quit:p=""  If $extract(nam,1,$length(p))=p,$data(^Sources(ext,p),found) Quit
	If $data(found)=0,$data($$$SourceMapping(ext,"*"),found),'$$$GetSourceMapping(ext,"*","NoFolders") Set default=1
	If $data(found)=0 Quit ""
	If InternalName["/" {
		// If no specific mapping was specified (p=""), then return the whole csp filename; otherwise return the name without the mapped piece
		Set InternalName=$extract(InternalName,$length(p)+2,*)
		Quit $translate(found_$translate(InternalName,"%","_"),"\","/")
	}
	If (ext="DFI") {
		// expected format is <folderName>-<itemName>.<itemType>.DFI; will map to an external file named <folderName>/<itemName>.<itemType>.xml 
		// replace the first '-' with '/' to translate Item Folder into subfolder on disk and leave the other dashes as dashes; converts spaces to '_'
		Quit $translate(found_$replace($translate(nam,"% ","__"),"-","/",1,1)_".xml","\","/")	
	}
	If ext="CLS"||(ext="PRJ")||(usertype&&(##class(%RoutineMgr).UserType(InternalName))) {
		Set nam=$translate(nam,"%")
		If '$$$GetSourceMapping(ext,"*","NoFolders") Set nam=$translate(nam,".","/")
		#; If match ends in '`' character use UDL/CLS format rather than XML format
		RETURN $translate(found_nam_".cls","\","/")
	}
	Quit $translate($g(found)_$tr(nam,"%.","_/")_"."_$zconvert(ext,"l"),"\","/")
}

/*
	NameToInternalName(name): given a Unix-style slash path relative to repo root, 
	returns the internal name for that file (e.g., cls/SourceControl/Git/Utils.cls -> SourceControl.Git.Utils.CLS)
*/
ClassMethod NameToInternalName(Name, IgnorePercent = 1, IgnoreNonexistent = 1) As %String
{
	Set InternalName=""
	If ($ZCVT(Name,"U")'[$ZCVT($$$SourceRoot,"U")) {
		Set Name = ##class(%File).NormalizeFilename(..TempFolder()_Name)
	}
	If (##class(%File).Exists(Name)) {
		New %SourceControl //don't trigger source hooks with this test load to get the Name
		Set sc=$system.OBJ.Load(Name,"-d",,.outName,1)
		If ($data(outName)=1) || ($data(outName) = 11 && ($Order(outName(""),-1) = $Order(outName("")))) {
			//only set if a single Name was returned ... ignore multi-item files
			Set InternalName=outName
		}
	}
	If (InternalName="") {
		If ($ZCVT(Name,"U")'[$ZCVT($$$SourceRoot,"U")) {
			//w !, Name
			Quit ""	; file is not in ^Sources so translation cannot occur
		}
		Set name=$extract(Name,$length($$$SourceRoot)+1,*)
		Set name=$replace(name,"\","/")	; standardize slash direction
		If (name["/") {
			//file is in a subdirectory under the ^Sources root
			Set nam=$piece(name,"/",2,$length(name,"/")),extDir=$piece(name,"/")_"/"
			If nam="" Quit ""
		
			Set queryary=$query($$$SourceMapping(""),-1,dir), subscript=$qsubscript(queryary,1)
			While (queryary'="")&&(subscript'=0) {
				If (dir["/")&&(dir=extDir) {
					Set ext=subscript
					Quit
				}
				Set queryary=$query(@queryary,-1,dir)
				If (queryary="") {
					Quit
				}
				Set subscript=$qsubscript(queryary,1)
			}
		} Else {
			//there is no leading directory to remove 
			Set nam=name	
		}

		If ($get(ext)="/CSP/") {
			//loop through to find if any subscripts of /CSP/ match
			Set cspapp = $order($$$SourceMapping("/CSP/",""),-1,subdir)
			If (cspapp'="*"){
				Do {
					If $extract(name,1,$length(subdir))=subdir {
						Set InternalName=cspapp_$replace(name,subdir,"/")
						Quit
					}
					Set cspapp = $order($$$SourceMapping("/CSP/",cspapp),-1,subdir)
				} While cspapp'="*"
			}
			If InternalName="" {
				//Internal Name is just the remainder after the subdirectory was removed and the leading "/" is added back
				Set InternalName="/"_nam
			}
			If ($length(InternalName,"/")=2) {
				//this was a file dropped directly under /cspapp/ so treat it as a non-mapped file
				Set InternalName = ""
			}
		}
		Set fileExt=$zconvert($piece(nam,".",$length(nam,".")),"L")
		If (InternalName="")&&('$data(ext)=0)&&('$listfind($listbuild("xml","rtn"),fileExt)) {
			//no match found yet, and this is in a subdir for a specific document type (ext), however it is not in a typical export format
			//so treat it as a non-mapped file
			Kill ext			 	
		}
		If $data(ext)=0 {
			Quit ""
		}
		If (InternalName="") {
			//take our best guess based on the document extension mapped to that subdirectory
			Set nam=$piece(nam,".",1,$length(nam,".")-1)
			Set nam=$translate(nam,"_/","%.")
			Set InternalName=nam_"."_ext
			If (ext="CLS") {	; special handling for possible collissions between % and non-% classes of the same name
				Set alternateInternalName="%"_InternalName
				Set primaryExists=##class(%RoutineMgr).Exists(InternalName), alternateExists=##class(%RoutineMgr).Exists(alternateInternalName)
				If ('primaryExists)&&(alternateExists) { Set InternalName=alternateInternalName }	; it must have been a %-class as one by that name exists
				If (primaryExists)&&(alternateExists) { Quit "" }	;indeterminate as the class exists in % and non-% form in the DB
			}
		}
	}
	If ((IgnorePercent)&&($extract(InternalName)="%")) { Set InternalName = "" }	; don't return a result for % items if instructed to ignore them
	If ((IgnoreNonexistent)&&('##class(%RoutineMgr).Exists(InternalName))) { Set InternalName = "" }	; only return item names which exist in the DB
	Quit ..NormalizeInternalName(InternalName)
}

}

