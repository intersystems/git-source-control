Include (%occStatus, %occErrors, SourceControl.Git)

Class SourceControl.Git.Utils [ Abstract, ProcedureBlock ]
{

Parameter Storage = "^SYS(""SourceControl"",""Git"")";

Parameter InstallNamespace = "%SYS";

Parameter Slash = {$case($system.Version.GetOS(),"Windows":"\",:"/")};

/// Name of the file with version controlled items
Parameter GitMenuItems = ",Settings,Commit,Pull,Fetch,Push,Revert,";

Parameter ImportAfterGitMenuItems = ",Commit,Pull,Fetch,Push,";

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

ClassMethod MakeError(msg As %String) As %Status [ CodeMode = expression, Private ]
{
$$$ERROR(8012,"Git",msg)
}

ClassMethod TempFolder() As %String
{
    set context = ##class(SourceControl.Git.PackageManagerContext).%Get()
    if context.IsInGitEnabledPackage {
        quit context.Package.Root
    }
    quit $get(@..#Storage@("settings","namespaceTemp"),..DefaultTemp()_$translate($znspace,"%")_..#Slash)
}

ClassMethod MappingsNode() As %String [ CodeMode = expression ]
{
$Name(@..#Storage@("settings","mappings"))
}

ClassMethod PullEventClass() As %String [ CodeMode = expression ]
{
$Get(@..#Storage@("settings","pullEventClass"), ##class(SourceControl.Git.PullEventHandler.Default).%ClassName(1))
}

ClassMethod PercentClassReplace() As %Status [ CodeMode = expression ]
{
$Get(@..#Storage@("settings","percentClassReplace"), "")
}

/// Returns the current (or previous) value of the flag.
ClassMethod Locked(newFlagValue As %Boolean) As %Boolean
{
    set result = $get(@..#Storage@("settings","locked"),0)
    if $data(newFlagValue)#2 {
        set @..#Storage@("settings","locked") = ''newFlagValue
    }
    quit result
}

ClassMethod GitBinExists(ByRef version) As %Boolean
{
    // Intentionally leak this as an optimization.
    if $data(^||GitVersion,version)#2 && (version '= "") {
        quit 1
    }
    try {
        do ..RunGitCommand("--version",.err,.out)
        set version = out.ReadLine()
    } catch e {
        set version = ""
    }
    set ^||GitVersion = version
    quit (version '= "")
}

ClassMethod GitBinPath(Output isDefault) As %String
{
    set isDefault = 0
    set binPath = "git"
    if '$data(@..InstallNamespaceStorage()@("%gitBinPath"),binPath)#2 {
        set isDefault = 1
    }
    quit $case($extract(binPath),"""":binPath,:""""_binPath_"""")
}

ClassMethod GitUserName() As %String
{
    quit $get(@..#Storage@("settings","user",$username,"gitUserName"))
}

ClassMethod GitUserEmail() As %String
{
    quit $get(@..#Storage@("settings","user",$username,"gitUserEmail"))
}

ClassMethod PrivateKeyFile() As %String
{
    quit $get(@..#Storage@("settings","ssh","privateKeyFile"))
}

ClassMethod NeedSettings() As %Boolean [ CodeMode = expression ]
{
(..TempFolder() = "") || (..GitBinPath() = "") ||  (..GitBinPath() = """")
}

ClassMethod InstallNamespace() As %String [ CodeMode = expression ]
{
..#InstallNamespace
}

ClassMethod AddSlash(path As %String) As %String
{
    if path'="" && ($extract(path,*)'=..#Slash) {
        set path = path_..#Slash
    }
    quit path
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
    #dim menuName as %String = $piece(MenuName,",")
    #dim menuItemName as %String = $piece(MenuName,",",2)
    #dim ec as %Status = $$$OK
    
    if (..Type(InternalName) = "csp") && ($extract(InternalName,1) '= "/") {
        set InternalName = "/" _ InternalName
    }

    if (menuItemName = "Settings") {
        set Action = 2
        set Target = "/isc/studio/usertemplates/gitsourcecontrol/gitprojectsettings.csp?NSpace="_$namespace_"&Username="_$username
    } elseif (menuItemName = "Init") {
        if ##class(%File).CreateDirectoryChain(..TempFolder()) {
            // cleanup items info
            kill @..#Storage@("items")
            kill @..#Storage@("TSH")
            do ..RunGitCommand("init",.errStream,.outStream)
            $$$NewLineIfNonEmptyStream(errStream)
            do errStream.OutputToDevice()
            $$$NewLineIfNonEmptyStream(outStream)
            do outStream.OutputToDevice()
        } else {
            set ec = ..MakeError("Unable to create folder "_..TempFolder())
        }
    } elseif (menuItemName = "GitWebUI") {
        set Action = 2
        set Target = "/isc/studio/usertemplates/gitsourcecontrol/webuidriver.csp/"_$namespace_"/"_$zconvert(InternalName,"O","URL")
    } elseif (menuItemName = "Export") || (menuItemName = "ExportForce") {
        write !, "==export start==",!
        set ec = ..ExportAll($case(menuItemName="ExportForce",1:$$$Force,:0))
        if ec {
            write !,"==export done==",!
        }
    } elseif (menuItemName = "Import") {
        set ec = ..ImportAll()
        set Reload = 1
    } elseif (menuItemName = "ImportForce") {
        set ec = ..ImportAll($$$Force)
        set Reload = 1
    } elseif (menuItemName = "%OpenRepoFolder") {
        set Action = 3
        set Target = ..TempFolder()
    } elseif (menuItemName = "Revert") {
        set Reload = 1
        quit ..Revert(InternalName)
    } elseif (menuItemName = "NewBranch") {
        set Target = "Please enter the name of the new branch"
        set Action = 7
        quit $$$OK
    } elseif (menuItemName = "SwitchBranch") {
        set Target = "Please enter the name of the existing branch"
        set Action = 7
        quit $$$OK
    } elseif (menuItemName = "Commit") {
        set Target = "Please enter a commit message"
        set Action = 7
        quit $$$OK
    } elseif (menuItemName = "Push") {
        quit ..Push()
    } elseif (menuItemName = "Fetch") {
        $$$QuitOnError(..Fetch(.diffFiles))
        set pointer = 0
        write !, !, "Changed Files: "
        while $listnext(diffFiles, pointer, item){
            write !,?4, item
        }
        write !
    } elseif (menuItemName = "Pull") {
        quit ..Pull()
    } elseif (menuItemName = "AddToSC") {
        set ec = ..AddToSourceControl(InternalName)
    } elseif (menuItemName = "RemoveFromSC") {
        set ec = ..RemoveFromSourceControl(InternalName)
    } elseif (menuItemName = "Commit") {
        set Target = "Please enter a commit message"
        set Action = 7
        quit $$$OK
    }
    quit ec
}

ClassMethod AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
    #dim menuName as %String = $piece(Name,",")
    #dim menuItemName as %String = $piece(Name,",",2)
    if (menuItemName = "Revert") || (menuItemName [ "Import") {
        set Reload = 1
    }
    if (menuItemName = "Commit") {
        if (Answer = 1) {
            do ..Commit(InternalName, Msg)
            set Reload = 1
        }
    } elseif (menuItemName = "NewBranch") {
        if (Answer = 1) {
            do ..NewBranch(Msg)
            set Reload = 1
        }
    } elseif (menuItemName = "SwitchBranch") {
        if (Answer = 1) {
            do ..SwitchBranch(Msg)
            set Reload = 1
        }
    }
    quit $$$OK
}

ClassMethod Revert(InternalName As %String) As %Status
{
    set filename = ..FullExternalName(InternalName)
    do ..RunGitCommand("checkout", .errStream, .outStream, "--", filename)
    $$$QuitOnError(##class(SourceControl.Git.Change).RemoveUncommitted(filename,0,1))
    $$$QuitOnError(##class(SourceControl.Git.Change).RefreshUncommitted(0,1))
    $$$QuitOnError(..ImportItem(InternalName,1))
    quit $$$OK
}

ClassMethod Commit(InternalName As %String, Message As %String = "example commit message") As %Status
{
    set filename = ..FullExternalName(InternalName)
    set username = ..GitUserName()
    set email = ..GitUserEmail()
    set author = username_" <"_email_">"
    do ..RunGitWithArgs(.errStream, .outStream, "commit", "--author", author, "-m", Message, filename)
    $$$NewLineIfNonEmptyStream(outStream)
    do outStream.OutputToDevice()
    $$$NewLineIfNonEmptyStream(errStream)
    do errStream.OutputToDevice()
    $$$QuitOnError(##class(SourceControl.Git.Change).RemoveUncommitted(filename))
    $$$QuitOnError(##class(SourceControl.Git.Change).RefreshUncommitted())
    quit $$$OK
}

ClassMethod NewBranch(newBranchName As %String) As %Status
{
    do ..RunGitWithArgs(.errStream, .outStream, "checkout", "-b", newBranchName)
    $$$NewLineIfNonEmptyStream(errStream)
    do errStream.OutputToDevice()
    $$$NewLineIfNonEmptyStream(outStream)
    do outStream.OutputToDevice()
    quit $$$OK
}

ClassMethod SwitchBranch(targetBranchName As %String) As %Status
{
    do ..RunGitWithArgs(.errStream, .outStream, "checkout", targetBranchName)
    $$$NewLineIfNonEmptyStream(errStream)
    do errStream.OutputToDevice()
    $$$NewLineIfNonEmptyStream(outStream)
    do outStream.OutputToDevice()
    quit $$$OK
}

ClassMethod Push(remote As %String = "origin") As %Status
{
    do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("branch",,.errStream,.outstream,"--show-current")
    set branchName = outstream.ReadLine(outstream.Size)
    do ..RunGitWithArgs(.errStream, .outStream, "push", remote, branchName)
    $$$NewLineIfNonEmptyStream(errStream)
    do errStream.OutputToDevice()
    $$$NewLineIfNonEmptyStream(outStream)
    do outStream.OutputToDevice()
    quit $$$OK
}

ClassMethod Fetch(ByRef diffFiles) As %Status
{
    do ..RunGitCommand("fetch", .errStream, .outStream)
    write !, "Fetch done"
    kill errStream, outStream
    do ..RunGitCommand("diff", .errStream, .outStream, "..origin", "--name-only")
    set diffFiles = ""
    while (outStream.AtEnd = 0) {
        set diffFiles = diffFiles_$listbuild(outStream.ReadLine())
    }
    quit $$$OK
}

ClassMethod Pull(remote As %String = "origin") As %Status
{
    #define Force 1
    do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("branch",,.errStream,.outStream,"--show-current")
    set branchName = outStream.ReadLine(outStream.Size)
    write !, "Pulling from branch: ", branchName

    set sc =  ##class(SourceControl.Git.Utils).RunGitCommandWithInput("fetch",,.errStream,.outStream, remote, branchName)
    if (sc=1){
        $$$NewLineIfNonEmptyStream(errStream)
        do errStream.OutputToDevice()
        quit sc
    }

    write !, "Fetch done"
    write !, "Files that will be modified by git pull: "

    do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("diff",,.errStream,.outStream, (branchName_"..."_(remote_"/"_branchName)), "--name-status")
    while (outStream.AtEnd = 0) {
        set file = outStream.ReadLine()
        set modification = ##class(SourceControl.Git.Modification).%New()
        set modification.changeType = $piece(file, $c(9), 1)
        set modification.externalName = $zstrip($piece(file, $c(9),2),"<W")
        if (modification.changeType '= "A"){
            set modification.internalName = ##class(SourceControl.Git.Utils).NameToInternalName(modification.externalName,,0)
        }
        else {
            set modification.internalName = ""
        }
        set files($increment(files)) = modification
        write !, ?4, modification.changeType, ?4, modification.internalName, ?4 , modification.externalName
    }
    if ('$data(files)) {
        write !, ?4, "None"
        write !, "Already up to date. Git Pull will not be executed."
        quit $$$OK
    }

    set sc = ..RunGitWithArgs(.errStream, .outStream, "pull", remote, branchName)
    if (sc=1){
        $$$NewLineIfNonEmptyStream(errStream)
        do errStream.OutputToDevice()
        $$$NewLineIfNonEmptyStream(outStream)
        do outStream.OutputToDevice()
        quit $$$ERROR(5001, "Pull event handler not called. Fix errors before compiling.")
    }
    $$$NewLineIfNonEmptyStream(outStream)
    do outStream.OutputToDevice()
    write !

    set key = $order(files(""))
    set deletedFiles = ""
    set addedFiles = ""
    while(key '= "") {
        set modification = files(key)
        if (modification.changeType = "D"){
            set deletedFiles = deletedFiles_","_modification.internalName
        } elseif (modification.changeType = "A"){
            set modification.internalName = ##class(SourceControl.Git.Utils).NameToInternalName(modification.externalName,,0)
            set addedFiles = addedFiles_","_modification.internalName
            set files(key) = modification
        }
        set key = $order(files(key))
    }

    set deletedFiles = $extract(deletedFiles, 2, *)
    set addedFiles = $extract(addedFiles, 2, *)
    
    if (deletedFiles '= ""){
        set sc = ##class(SourceControl.Git.Utils).RemoveFromServerSideSourceControl(deletedFiles)
    }
    if (addedFiles '= ""){
        set sc = ##class(SourceControl.Git.Utils).AddToServerSideSourceControl(addedFiles)
    }

    set event = $classmethod(..PullEventClass(),"%New")
    set event.LocalRoot = ..TempFolder()
    merge event.ModifiedFiles = files
    quit event.OnPull()
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
    set folder = $translate(folder, "/", ..#Slash)
    set:$extract(folder)=..#Slash $extract(folder) = ""
    set:$extract(folder,*)'=..#Slash folder = folder _ ..#Slash
    quit folder
}

ClassMethod ExternalName(InternalName As %String, ByRef MappingExists As %Boolean) As %String
{
    quit ..Name(InternalName,.MappingExists)
}

ClassMethod AddToServerSideSourceControl(InternalName As %String) As %Status
{
     #dim i as %Integer
    #dim ec as %Status = $$$OK
    for i = 1:1:$length(InternalName, ",") {
        #dim item as %String = ..NormalizeExtension($piece(InternalName, ",", i))
        set @..#Storage@("items", item) = ""
        #dim sc as %Status =  ..ImportItem(item, 1)
        if 'sc {
            set ec = $$$ADDSC(ec, sc)
        }
    }
    quit ec
}

ClassMethod AddToSourceControl(InternalName As %String) As %Status
{
    #dim i as %Integer
    #dim ec as %Status = $$$OK
    for i = 1:1:$length(InternalName, ",") {
        #dim item as %String = ..NormalizeExtension($piece(InternalName, ",", i))
        #dim type as %String = ..Type(item)

        #dim sc as %Status =  ..ExportItem(item,,1,.filenames)
        if 'sc {
            set ec = $$$ADDSC(ec, sc)
        }
        for i=1:1:$Get(filenames) {
            set FileInternalName = ##class(SourceControl.Git.Utils).NormalizeExtension(##class(SourceControl.Git.Utils).NameToInternalName(filenames(i), 0,,1))
            if (FileInternalName = "") {
                continue
            }
            set FileType = ##class(SourceControl.Git.Utils).Type(FileInternalName)

            set @..#Storage@("items", FileInternalName) = ""
            do ..RunGitCommand("add",.errStream,.outStream,filenames(i))
            write !, "Added ", FileInternalName, " to source control."
            $$$NewLineIfNonEmptyStream(outStream)
            do outStream.OutputToDevice()
            $$$NewLineIfNonEmptyStream(errStream)
            do errStream.OutputToDevice()
        }
    }
    quit ec
}

ClassMethod RemoveFromGit(InternalName)
{
    #dim fullName = ##class(Utils).FullExternalName(InternalName)
    do ..RunGitCommand("rm",.errStream,.outStream,"--cached", fullName)
    $$$NewLineIfNonEmptyStream(errStream)
    do errStream.OutputToDevice()
    $$$NewLineIfNonEmptyStream(outStream)
    do errStream.OutputToDevice()
}

ClassMethod DeleteExternalsForItem(InternalName As %String) As %Status
{
    #dim type as %String = ..Type(InternalName)
    #dim ec as %Status = $$$OK
    if (type = "prj") || (type = "pkg") || (type = "csp" && ..IsCspFolder(InternalName)) {
        // we delete complex items
        
        //get all item in files
        #dim itemsList
        $$$QuitOnError(..ListItemsInFiles(.itemsList))
        
        #dim item as %String = ""
        //for all item in files
        for {
            set item = $order(itemsList(item))
            quit:item=""
            
            //if item is not in sc -- delete file
            if '..IsInSourceControl(item) {
                #dim sc as %Status = ..DeleteExternalFile(item)
                if 'sc {
                    set ec = $$$ADDSC(ec, sc)
                }
                do ..RemoveFromGit(item)
            }
        }
    } else {
        set ec = ..DeleteExternalFile(InternalName)
        do ..RemoveFromGit(InternalName)
    }
    quit ec
}

ClassMethod FindTrackedFilesInPackage(InternalName As %String, ByRef trackedFiles As %String) As %Status
{
    Set sc = $$$OK
    set item = InternalName_"."
    set trackedFiles = ""
    for{
        set item = $order(@..#Storage@("items",item))
        quit:item'[InternalName_"."

        if ..IsClassInPackage(item, InternalName) {
            if (trackedFiles = ""){
                set trackedFiles = item
            }
            else {
                set trackedFiles = trackedFiles_","_item
            }
        }
    }
    Return sc
}

ClassMethod FindTrackedFilesInProjects(InternalName As %String, ByRef trackedFiles As %String) As %Status
{
    Set sc = $$$OK
    #dim item as %String = ""
    set trackedFiles = ""
    for{
        set item = $order(@..#Storage@("items",item))
        quit:item=""

        if ..IsItemInProject(item, InternalName) {
            if (trackedFiles = ""){
                set trackedFiles = item
            }
            else {
                set trackedFiles = trackedFiles_","_item
            }
        }
    }
    Return sc
}

ClassMethod FindTrackedFilesInCSPFolders(InternalName As %String, ByRef trackedFiles As %String) As %Status
{
    Set sc = $$$OK    
    set item = InternalName_"/"
    set trackedFiles = ""
    for  {
        set item = $order(@..#Storage@("items",item))
        quit:item'[InternalName_"/"
        
        if ..IsItemInCSPFolder(item, InternalName) {
            if (trackedFiles = ""){
                set trackedFiles = item
            }
            else {
                set trackedFiles = trackedFiles_","_item
            }
        }
    }
    Return sc
}

ClassMethod FindTrackedFiles(InternalName As %String, ByRef trackedFiles As %String) As %Status
{
   
    #dim type as %String = ..Type(InternalName)
    set InternalName = ..NameWithoutExtension(InternalName)

    if (type = "pkg") {
        set sc = ..FindTrackedFilesInPackage(InternalName, .trackedFiles)
    } elseif (type ="prj") {
        set sc = ..FindTrackedFilesInProjects(InternalName, .trackedFiles)
    } elseif (type = "csp") {
        set sc = ..FindTrackedFilesInCSPFolders(InternalName, .trackedFiles)
    }
    return sc
}

/// Description
ClassMethod FindTrackedParent(InternalName As %String, ByRef parentElement As %String) As %Status
{
    #dim type as %String = ..Type(InternalName)
    set isInSourceControl = 0
    if type = "cls" {
        #define StripExtension(%s) $Piece(%s,".",1,$Length(%s, ".") - 1)
        set className = $$$StripExtension(InternalName)
        set isInSourceControl = ..FindInPackages(InternalName, .parentElement)
        if (isInSourceControl){
            set parentElement = parentElement_".pkg"
        }
    } elseif type = "csp" {
        if $extract(InternalName) '= "/" {
            set InternalName = "/" _ InternalName
        }
        set isInSourceControl = ..FindInCspFolders(InternalName, .parentElement)
    }
    
    // our last chance to find item -- let's look in projects
    if 'isInSourceControl {
        set isInSourceControl = ..FindInProjects(InternalName, .parentElement)
        if (isInSourceControl){
            set parentElement = parentElement_".prj"
        }
    }

    quit isInSourceControl
}

ClassMethod RemoveFromServerSideSourceControl(InternalName As %String) As %Status
{
    #dim i as %Integer
    #dim ec as %Status = $$$OK
    for i = 1:1:$length(InternalName, ",") {
        #dim item as %String = ..NormalizeExtension($piece(InternalName, ",", i))
        #dim tsc as %Status = $$$OK
        #dim type as %String = ..Type(InternalName)
        
        if $data(@..#Storage@("items", item)) {
            kill @..#Storage@("items", item)
            do ..RemoveFolderIfEmpty(..TempFolder())
        } elseif (type = "cls") {
            set tsc = ..MakeError(item _ " is not in SourceControl")
        } 
        set ec = $$$ADDSC(tsc, ec)
    }
    quit ec
}

ClassMethod RemoveFromSourceControl(InternalName As %String, cascadeDelete As %Boolean = 1) As %Status
{
    write !
    #dim sc as %Status = $$$OK
    if (InternalName = ""){
        set sc = ..MakeError("Passed InternalName is empty!")
        quit sc
    }
    for i = 1:1:$length(InternalName, ",") {
        #dim tsc as %Status = $$$OK
        #dim type as %String = ..Type(InternalName)

        set item = $piece(InternalName, ",", i)
        if $data(@..#Storage@("items", ..NormalizeExtension(item))) {
            set item = ..NormalizeExtension(item)
        }
        
        if $data(@..#Storage@("items", item)) {
            kill @..#Storage@("items", item)
            set tsc = ..DeleteExternalsForItem(item)
        } elseif ((type="cls") || (type="inc") || (type="mac")){
             set tsc = ..MakeError(item _ " is not in SourceControl")
        }

        if (cascadeDelete) {        
            if ((type="pkg") || (type="csp") || (type="prj")) {
                set tsc = $$$ADDSC(tsc, ..FindTrackedFiles(InternalName, .trackedFiles))
                if (trackedFiles '= ""){
                    set tsc = $$$ADDSC(tsc, ..RemoveFromSourceControl(trackedFiles, 0))
                }
            }
        }
        do ..RemoveFolderIfEmpty(..TempFolder())

        
        set sc = $$$ADDSC(tsc, sc)
    }
    quit sc
}

ClassMethod IsCspFolder(InternalName As %String) As %Boolean
{
    #dim extension = $piece(InternalName, ".", $length(InternalName, "."))
    quit:extension="csp" 0
    
    #dim filename = $system.CSP.GetFileName(InternalName_"/")
    if filename = "" && ($extract(InternalName,1) '= "/") {
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
    #dim extension as %String = $zconvert($piece(InternalName,".",$length(InternalName,".")),"L")
    #dim type as %String = extension
    
    if ($extract(InternalName, 1, 4) = "/csp") || ($find(InternalName,".") = 0) || ($find(InternalName,"/") > 0) {
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
    #dim type as %String = ..Type(InternalName)
    #dim name as %String = $case(type, "cls": ..NameWithoutExtension(InternalName),
        "pkg": $translate(..NameWithoutExtension(InternalName), "/", "."),
        "csp": $extract(InternalName, 2, *),
        :InternalName)
    if $extract(name) = "." && (type = "pkg") {
        set $extract(name) = ""
    }
    
    #dim checkId = projectName_"||"_name_"||"_$zconvert(type,"U")
    #dim isItemInProject as %Boolean = ##class(%Studio.ProjectItem).%ExistsId(checkId)
    
    #dim i as %Integer
    if 'isItemInProject && ((type = "cls") || (type="pkg")) {
        for i = 1:1:$length(name, ".") {
            set checkId = projectName_"||"_$piece(name, ".", 1, i)_"||PKG"
            if ##class(%Studio.ProjectItem).%ExistsId(checkId) {
                set isItemInProject = 1
                quit
            }
        }
    }
    
    if 'isItemInProject && (type = "csp") {
        for i = 1:1:$length(name, "/") {
            set checkId = projectName_"||"_$piece(name, "/", 1, i)_"||DIR"
            
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
    #dim item as %String = ""
    #dim found as %Boolean = 0
    for  {
        set item = $order(@..#Storage@("items", item))
        quit:item=""
        continue:..Type(item)'="pkg"
        #dim packageName as %String = ..NameWithoutExtension(item)

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
    #dim item as %String = ""
    #dim found as %Boolean = 0
    for  {
        set item = $order(@..#Storage@("items", item))
        quit:item=""
        continue:..Type(item)'="prj"
        #dim projectName as %String = ..NameWithoutExtension(item)
        
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
    #dim cspFolder as %String = ""
    #dim found as %Boolean = 0
    for  {
        set cspFolder = $order(@..#Storage@("items", cspFolder))
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
    #dim isInSourceControl as %Boolean = 1
    set sourceControlItem = ""
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeExtension(InternalName)
    if (InternalName = "") {
        quit 0
    }
    
    set context = ##class(SourceControl.Git.PackageManagerContext).%Get()
    if $data(@..#Storage@("items", ..NormalizeExtension(InternalName))) {
        set InternalName = ..NormalizeExtension(InternalName)
    }
    
    set isInSourceControl = $data(@..#Storage@("items", InternalName)) > 0
    if isInSourceControl {
        // Direct reference to namespace-default project
        set sourceControlItem = InternalName
    } elseif context.IsInGitEnabledPackage && (InternalName = ..NormalizeExtension(context.InternalName)) {
        // Next thing to check is if we're in a package manager-based package
        set isInSourceControl = 1
        set sourceControlItem = context.ResourceReference.Name
    } else {
        // If no direct or package reference, look in packages, projects or csp-apps
        // We have three groups of routines
        // packages for classes
        // projects for everything
        // csp-folders for csp and static files

        #dim type as %String = ..Type(InternalName)
        if type = "cls" {
            #define StripExtension(%s) $Piece(%s,".",1,$Length(%s, ".") - 1)
            set className = $$$StripExtension(InternalName)
            if (InternalName '= "") && (className '= "") && ($$$defClassKeyGet(className,$$$cCLASSgeneratedby)'="") {
                set isInSourceControl = 0 // skip generated classes
            } else {
                set isInSourceControl = ..FindInPackages(InternalName, .sourceControlItem)
            }
        } elseif type = "csp" {
            if $extract(InternalName) '= "/" {
                set InternalName = "/" _ InternalName
            }
            set isInSourceControl = ..FindInCspFolders(InternalName, .sourceControlItem)
        }
        
        // our last chance to find item -- let's look in projects
        if 'isInSourceControl {
            set isInSourceControl = ..FindInProjects(InternalName, .sourceControlItem)
        }
    }
    quit isInSourceControl
}

ClassMethod FullExternalName(InternalName As %String, ByRef MappingExists As %Boolean) As %String [ CodeMode = expression ]
{
##class(%File).NormalizeFilename(..TempFolder()_..ExternalName(InternalName, .MappingExists))
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
    
    if $extract(name) '= "/" {
        quit $piece(name,".",1,*-1)_"."_$zconvert($piece(name,".",*),"U")
    }
    
    set type = ..Type(name)
    
    if (type = "inc") || (type = "mac") || (type = "int") {
        set name = $extract($translate(name, "/", "."), 2, *)
    }
    quit name
}

ClassMethod NormalizeExtension(name As %String) As %String
{
    #dim extension = $piece(name, ".", $length(name, "."))
    if $length(extension) <= 3 {
        set $piece(name, ".", $length(name, ".")) = $zconvert(extension, "L")
    }
    quit name
}

ClassMethod RoutineTSH(InternalName As %String) As %String
{
    #dim type = ..Type(InternalName)
    //for csp-files (csp,js,html,css, all that stored in csp/...) we always check for changes in external file
    #dim tsh = $case(type,"csp":"",:$get(@..#Storage@("TSH", ..NormalizeExtension(InternalName))))
    if tsh = "" {
        #dim ts as %String = ##class(%RoutineMgr).TS(InternalName)
        if ts '= "" {
            // prj files have milliseconds in timestamp, so we crop them
            set tsh = $piece($zdatetimeh(ts, 3),".",1)
        } else {
            set tsh = "1840-12-31 00:00:00"
        }
    }
    quit tsh
}

ClassMethod UpdateRoutineTSH(InternalName As %String, tsh As %String) As %Status
{
    set @..#Storage@("TSH", ..NormalizeExtension(InternalName)) = $get(tsh, $h)
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
    #dim ec as %Status = $$$OK
    if ##class(%File).Exists(fullName) {
        set ec = ##class(%File).Delete(fullName)
        do ..RemoveRoutineTSH(InternalName)
        write !, fullName, " for ", InternalName, " deleted"
    }
    quit ec
}

/// if temp file for InternalName not found return "0,0" in tempFileTSH
ClassMethod GetTempFileAndRoutineTS(InternalName As %String, ByRef tempFileTSH As %String, ByRef routineTSH As %String)
{
    #dim filename as %String = ..FullExternalName(InternalName)
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
    #dim loadedProject as %String = $piece(projectName, ".", 1)
    // now we should fix reference to csp pages in project items
    // that is: if project was exported from USER and imported in SAMPLES
    // then all reference to csp/user/page.csp should be changed to csp/samples/page.csp
    #dim item as %String =""
    #dim oldCspApp as %String = ""
    #dim newCspApp as %String = ""
    for  {
        set item = $order(^oddPROJECT(loadedProject,"Items",item))
        quit:item=""
        set type = $order(^oddPROJECT(loadedProject,"Items",item,""))
        if type = "CSP" || (type = "DIR") {
            #dim newitem as %String = item
            set $piece(newitem,"/",1,2) = $extract($system.CSP.GetDefaultApp($znspace),2,*)
            if newitem '= item {
                set ^oddPROJECT(loadedProject,"Items",newitem,type) = ^oddPROJECT(loadedProject,"Items",item,type)
                kill ^oddPROJECT(loadedProject,"Items",item,type)
                set newCspApp = $extract($system.CSP.GetDefaultApp($znspace),2,*)
                set oldCspApp = $piece(item,"/",1,2)
            }
        }
    }
    quit $$$OK
}

/// imports file if version in system is newer then version on disk.
/// if <var>force</var> = 1 then imports in any case.
ClassMethod ImportItem(InternalName As %String, force As %Boolean = 0, verbose As %Boolean = 1) As %Status
{
    #dim filename as %String = ..FullExternalName(InternalName)
    #dim fileTSH = ##class(%File).GetFileDateModified(filename)
    #dim sc as %Status = $$$OK
    
    if ..IsRoutineOutdated(InternalName) || force {
        if ##class(%RoutineMgr).UserType(InternalName,.docclass,.doctype) {
            set routineMgr = ##class(%RoutineMgr).%OpenId(InternalName)
            do routineMgr.Code.Rewind()
            set source = ##class(%Stream.FileCharacter).%OpenId(filename,,.sc)
            if $$$ISOK(sc) {
                do routineMgr.Code.CopyFrom(source)
                set sc = routineMgr.%Save()
            }
        } else {
            if ($extract(InternalName, 1) = "/"){
                set sc = ..ImportCSPFile(InternalName)
            } else{
                set sc = $system.OBJ.Load(filename,"-l-d")
            }
        }
        if sc {
            set sc = ..UpdateRoutineTSH(InternalName, fileTSH)
            if ..Type(InternalName) = "prj" {
                set sc = $$$ADDSC(sc, ..FixProjectCspReferences(InternalName))
            }
            write !, InternalName," has been imported from ", filename
        } else {
            write !, "ERROR importing" ,InternalName, !
            do $system.Status.DisplayError(sc)
        }
    } elseif verbose {
        write !, InternalName, " is the same as on-disk version or newer, skipping import",!
    }
    quit sc
}

ClassMethod ImportCSPFile(InternalName As %String) As %Status
{
    set cspFile = $System.CSP.GetFileName(InternalName)
    set srcFile = ..FullExternalName(InternalName)
    set sc = $$$OK

    if (cspFile=srcFile)||($$$isWINDOWS&&($ZCVT(cspFile,"l")=$ZCVT(srcFile,"l"))) {
        Quit $$$OK
    }

    if '(##class(%File).Delete(cspFile) && ##class(%File).CopyFile(srcFile, cspFile)) {
        set sc = $$$ERROR($$$GeneralError, "Unable to import '"_srcFile_"'")
    }

    Quit sc
}

ClassMethod ListItemsInFiles(ByRef itemList, ByRef err) As %Status
{
    #define DoNotLoad 1
    
    set mappingFileType = $order($$$SourceMapping(""))
    while (mappingFileType '= "") {

        set mappingCoverage = $order($$$SourceMapping(mappingFileType, ""))

        while (mappingCoverage '= ""){

            set mappedRelativePath = $$$SourceMapping(mappingFileType, mappingCoverage)
            set mappedFilePath = ##class(%File).NormalizeFilename(mappedRelativePath, ..TempFolder())
            
            if (##class(%File).DirectoryExists(mappedFilePath)){
                set res = $system.OBJ.ImportDir(mappedFilePath,,"-d",.err,1, .tempItemList, $$$DoNotLoad)
                merge itemList = tempItemList
            }

            set mappingCoverage = $order($$$SourceMapping(mappingFileType, mappingCoverage))
        }

        set mappingFileType = $order($$$SourceMapping(mappingFileType))
    }

    if '$data(itemList) && $$$ISERR(res) {
        quit res
    }
    
    if $get(err) > 0 {
        write !, "There were some errors while importing files"
        for i=1:1:err {
            write !, err(i)
        }
    }
    
    //change all csp/ names to /csp/ names
    #dim item as %String = "csp"
    for  {
        set item = $order(itemList(item))
        quit:item=""
        quit:$extract(item, 1, 4)'="csp/"
        kill itemList(item)
        set itemList("/"_item)=""
    }
    quit $$$OK
}

ClassMethod ImportRoutines(force As %Boolean = 0) As %Status
{
    write !, "==import start=="
    
    #dim err, itemList
    
    kill err, itemList
    set err = 0
    
    #dim ec as %Status = ..ListItemsInFiles(.itemList, .err)
    quit:'ec ec
    
    #dim internalName as %String = ""
    for  {
        set internalName = $order(itemList(internalName))
        quit:internalName=""
        if '..IsInSourceControl(internalName) {
            continue
        }
        #dim sc as %Status = ..ImportItem(internalName, force)
        if $$$ISERR(sc) {
            set ec = $$$ADDSC(ec, sc)
        }
    }
    
    //let's delete all items for which corresponding files had been deleted
    #dim item as %String = ""
    for  {
        set item = $order(@..#Storage@("TSH", item))
        quit:item=""

        if '##class(%File).Exists(..FullExternalName(item)) {
            #dim type as %String = ..Type(item)
            #dim name as %String = ..NameWithoutExtension(item)
            #dim deleted as %Boolean = 1
            if type = "prj" {
                set ec = $$$ADDSC(ec, $system.OBJ.DeleteProject(name))
            }elseif type = "cls" {
                set ec = $$$ADDSC(ec, $system.OBJ.Delete(item))
            }elseif $listfind($listbuild("mac","int","inc","bas","mvb","mvi","dfi"), type) > 0 {
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
                kill $$$TrackedItems(..NormalizeExtension(item))
                write !, item, " was deleted"
            } else {
                if +$system.Status.GetErrorCodes(ec) '= $$$ClassDoesNotExist {
                    write !, "Error: could not delete ", item
                } else {
                    // if something we wanted to delete is already deleted -- good!
                    set ec = $$$OK
                }
            }
        }
    }
    
    write !, "==import done=="
    quit ec
}

ClassMethod ExportRoutinesAux(path As %String, sep As %String = "", level As %Integer = 0, force As %Boolean = 0, ByRef filenames) As %Status
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
    
    #dim rs as %ResultSet = ##class(%ResultSet).%New("%RoutineMgr:StudioOpenDialog")
    #dim ec as %Status = rs.Execute(path_$case(path,"":"",:"/")_"*",$$$Dir, $$$OrderBy, $$$SystemFiles, $$$Flat, $$$NotStudio, $$$ShowGenerated, $$$Filter)
    quit:'ec ec
    while rs.Next() {
        #dim name as %String = rs.Get("Name")
        #dim isdirectory as %String = rs.Get("IsDirectory")
        #dim type as %String = rs.Get("Type")
        
        if (type = $$$Directory) || (type = $$$CSPFolder) {
            #dim newpath as %String = $case(path,"":name,:path_isdirectory_name)
            do ..ExportRoutinesAux(newpath, isdirectory, level + 1, force, .filenames)
        } else {
            #dim InternalName as %String = path_sep_name
            if (type = $$$CspFile) && ($extract(InternalName) '= "/") {
                set InternalName = "/"_InternalName
            }
            set ec = ..ExportItem(InternalName, 1, force, .filenames)
        }
    }
    kill rs
    quit ec
}

ClassMethod ExportItem(InternalName As %String, expand As %Boolean = 1, force As %Boolean = 0, ByRef filenames) As %Status
{
    #dim type = ..Type(InternalName)
    if type = "pkg" {
        $$$QuitOnError(..ExportRoutinesAux(..NameWithoutExtension(InternalName), ".", 0, force, .filenames))
    }elseif type = "prj" && expand {
        $$$QuitOnError(..ExportProject(..NameWithoutExtension(InternalName), force, .filenames))
        $$$QuitOnError(..ExportItem(InternalName, 0, force, .filenames))
    }elseif (type = "csp") && ..IsCspFolder(InternalName) {
        $$$QuitOnError(..ExportRoutinesAux(InternalName , "/", 0, force, .filenames))
    }else {
        if ..IsTempFileOutdated(InternalName) || force {
            #dim filename as %String = ..FullExternalName(InternalName, .MappingExists)
            if (MappingExists = 0){
                write "Did not find a matching mapping for """_InternalName_""". Skipping export."
                quit $$$OK
            }
            set filenames($I(filenames)) = filename
            write !, "exporting new version of ", InternalName, " to ", filename
            $$$QuitOnError($system.OBJ.ExportUDL(InternalName, filename,"-d/diff"))
            $$$QuitOnError(..UpdateRoutineTSH(InternalName, $h))
            if '##class(SourceControl.Git.Change).IsUncommitted(filename) {
                $$$ThrowOnError(##class(SourceControl.Git.Change).SetUncommitted(filename, "add", InternalName, $username, "", 1, "", "", 0))
            }
        }
    }
    quit $$$OK
}

ClassMethod ExportProject(project As %String, force As %Boolean = 0, ByRef filenames) As %Status
{
    #dim rs as %ResultSet = ##class(%ResultSet).%New("%Studio.Project:ProjectItemsList")
    $$$QuitOnError(rs.Execute(project))
    #dim typesWithoutExtension as %List = $listbuild("CLS", "PKG")
    while rs.Next() {
        #dim name = rs.Get("Name")
        if $listfind(typesWithoutExtension, rs.Get("Type")) {
            set name = name _ "." _ rs.Get("Type")
        }
        #dim ec as %Status = ..ExportItem(name, 1, force, .filenames)
        quit:'ec
    }
    kill rs
    quit $$$OK
}

/// if <var>force</var> = 1 then we export item even if timestamp in system is older
ClassMethod ExportAll(force As %Boolean = 0) As %Status
{
    quit ..ExportRoutines(force)
}

/// if <var>force</var> = 1 then we import item even if timestamp in system is newer
ClassMethod ImportAll(force As %Boolean = 0) As %Status
{
    quit ..ImportRoutines(force)
}

ClassMethod ExportRoutines(force As %Boolean = 0) As %Status
{
    #dim item as %String = ""
    #dim ec as %Status = $$$OK
    for  {
        set item = $order(@..#Storage@("items",item))
        quit:item=""
        set ec = ..ExportItem(item, 1, force)
        quit:'ec
    }
    quit ec
}

/// returns true if directory was deleted
ClassMethod RemoveFolderIfEmpty(path As %String) As %Boolean
{
    #dim rs as %ResultSet = ##class(%ResultSet).%New("%File:FileSet")
    #define DirsFirst 1
    $$$QuitOnError(rs.Execute(path,,,$$$DirsFirst))
    #dim fileCount as %Integer = 0
    while rs.Next() {
        #dim fullname as %String = rs.Get("Name")
        #dim type as %String = rs.Get("Type")
        #dim name as %String = rs.Get("ItemName")
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

ClassMethod RunGitWithArgs(Output errStream, Output outStream, args...) As %Integer
{
    set command = args(1)
    for i=2:1:$get(args) {
        set newArgs($increment(newArgs)) = args(i)
    }
    quit ..RunGitCommand(command,.errStream,.outStream,newArgs...)
}

ClassMethod RunGitCommand(command As %String, Output errStream, Output outStream, args...) As %Integer
{
    quit ..RunGitCommandWithInput(command,,.errStream,.outStream,args...)
}

ClassMethod RunGitCommandWithInput(command As %String, inFile As %String = "", Output errStream, Output outStream, args...) As %Integer
{
    set newArgs($increment(newArgs)) = "-C"
    set newArgs($increment(newArgs)) = ..TempFolder()

    set privateKeyFile = ..PrivateKeyFile()
    if (privateKeyFile '= "") {
        if $$$isWINDOWS {
            // Escape slashes
            set privateKeyFile = $replace(privateKeyFile,"\","\\")
        }
        set newArgs($increment(newArgs)) = "-c"
        // StrictHostKeyChecking=accept-new for good behavior on first connection
        set newArgs($increment(newArgs)) = "core.sshCommand=ssh -F /dev/null -o StrictHostKeyChecking=accept-new -i "_privateKeyFile
    }

    set username = ..GitUserName()
    set email = ..GitUserEmail()

    set newArgs($increment(newArgs)) = "-c"
    set newArgs($increment(newArgs)) = "user.name="_username
    set newArgs($increment(newArgs)) = "-c"
    set newArgs($increment(newArgs)) = "user.email="_email

    set newArgs($increment(newArgs)) = command

    for i=1:1:$get(args) {
        if ($data(args(i))) {
            set newArgs($increment(newArgs)) = args(i)
        }
    }

    set outLog = ##class(%Library.File).TempFilename()
    set errLog = ##class(%Library.File).TempFilename()

    set command = $extract(..GitBinPath(),2,*-1)
    set returnCode = $zf(-100,"/STDOUT="_$$$QUOTE(outLog)_" /STDERR="_$$$QUOTE(errLog)_$case(inFile, "":"", :" /STDIN="_$$$QUOTE(inFile)),command,newArgs...)

    set errStream = ##class(%Stream.FileCharacter).%OpenId(errLog,,.sc)
    set outStream = ##class(%Stream.FileCharacter).%OpenId(outLog,,.sc)
    set outStream.TranslateTable="UTF8"
    for stream=errStream,outStream {
        set stream.RemoveOnClose = 1
    }
    quit returnCode
}

ClassMethod GitStatus(ByRef files, IncludeAllFiles = 0)
{
    do ..RunGitCommand("status", .errStream, .outStream, "-z", "-uall")
    set lines = outStream.ReadLine()
    set list = $listfromstring(lines, $char(0))
    set pointer = 0
    while $listnext(list, pointer, item) {
        set operation = $zstrip($extract(item, 1, 2), "<W")
        set externalName = $extract(item, 4, *)
        set internalName = ..NameToInternalName(externalName)
        if (internalName '= "") {
            set files(internalName) = $listbuild(operation, externalName)
        } elseif ((IncludeAllFiles) && (externalName '= "")) {
            set externalName = $TRANSLATE(externalName, "\", "/")
            set files($I(files)) = $listbuild(operation, externalName)
        } 
    }
}

/*
    Internal name: e.g. SourceControl.Git.Utils.CLS
    External name e.g. cls/SourceControl/Git/Utils.cls
	Name(InternalName): returns Unix-style slash path relative to repo root cooresponding to internal name 
	(e.g., cls/SourceControl/Git/Utils.cls)
*/
ClassMethod Name(InternalName As %String, ByRef MappingExists As %Boolean) As %String
{
   
    set MappingExists = -1
    set InternalName=##class(%Studio.SourceControl.Interface).normalizeName(InternalName)
    set context = ##class(SourceControl.Git.PackageManagerContext).%Get()
    if (context.IsInGitEnabledPackage) && (InternalName = context.InternalName) && $isobject(context.ResourceReference) {
        set relativePath = context.ResourceReference.Processor.OnItemRelativePath(InternalName)
        quit relativePath
    }
    set usertype=$system.CLS.IsMthd("%Library.RoutineMgr","UserType")
    
    // For an abstract document, use the GetOther() method to try to determine its "real" class
    if usertype,##class(%RoutineMgr).UserType(InternalName,.docclass,.doctype) {
        // Check for a real abstract document subclass (or GetOther() may not work)
        if $classmethod(docclass,"%IsA","%Studio.AbstractDocument") {
            // Grab the actual name
            set actualName = $classmethod(docclass,"GetOther",InternalName)
            // The actualName is only valid if we get a single .cls as a result
            if (actualName'[",") && ($zconvert($piece(actualName,".",$length(actualName,".")),"U")="CLS") {
                // We use what GetOther() gives us, thus Demo.Loan.FindRateProcess.bpl becomes Demo.Loan.FindRateProcess.cls
                set InternalName = actualName
            }
        }
    }
    
    if $$CheckProtect^%qccServer(InternalName) {
        quit ""
    }
       
    set nam=$piece(InternalName,".",1,*-1)
    set ext=$zconvert($piece(InternalName,".",*),"u")

    if (nam="")||(ext=""){
        quit ""
    }

    if (ext="ZPM") {
        // Don't try to do anything with package file
        quit ""
    }

    // Any CSP items should be matched against the "/CSP/" mapping in ^Sources
    if InternalName["/" {
        set filename=$$GetFilename^%apiCSP(InternalName)
        //Find if this csp file is located within the ^Sources tree, and return appropriate value
        if ($$$isWINDOWS) && ($zconvert($extract(filename,1,$length($$$SourceRoot)),"l")=$zconvert($$$SourceRoot,"l")){
            quit $extract(filename,$length($$$SourceRoot)+1,*)
        } elseif $extract(filename,1,$length($$$SourceRoot))=$$$SourceRoot{
            quit $extract(filename,$length($$$SourceRoot)+1,*)
        }
        //Do not support manipulating files in the /itemsetsourcelink* csp app which are not inside of the namespace's ^Sources tree
        if InternalName["itemsetsourcelink" {
            write !,"To control files in the /itemsetsourcelink* web app, they must be in this tree: "_$$$SourceRoot_" ("_InternalName_" is located at "_filename_")"
            quit ""
        }
        // Any CSP items should be matched against the "/CSP/" mapping if the file is not stored in the ^Sources tree
        set ext="/CSP/"
    }

    if (ext="PRJ") && (nam["Default_"){
        quit ""
    } 

    if (ext="CLS") && ($$$defClassKeyGet(nam,$$$cCLASSgeneratedby)'=""){
        quit ""
    } 
    
    set default=0
    set p=$order($$$SourceMapping(ext,nam))
    for{
        set p=$order($$$SourceMapping(ext,p),-1) 
        quit:p=""  
        if ($extract(nam,1,$length(p))=p) && ($data($$$SourceMapping(ext,p),found)){
            if $data($$$SourceMapping(ext,p,"NoFolders")){
                set default=0
            } else {
                set default=1
            }
            quit
        }
    }
    
    if ($data(found)=0){
        if ($data($$$SourceMapping(ext,"*"),found)=1) && ('$$$GetSourceMapping(ext,"*","NoFolders")){
            set default=1
        } elseif $data($$$SourceMapping(ext,"*","NoFolders")){
            set default=0
        } elseif $data(found)=0{
            set found = $zconvert(ext,"L")_"/"
            set MappingExists = 0
        }
    }

    if (MappingExists '= 0){
        set MappingExists = 1
    }

    if InternalName["/" {
        // If no specific mapping was specified (p=""), then return the whole csp filename; otherwise return the name without the mapped piece
        set InternalName=$extract(InternalName,$length(p)+2,*)
        quit $translate(found_$translate(InternalName,"%","_"),"\","/")
    
    } elseif ext="CLS"||(ext="PRJ")||(usertype&&(##class(%RoutineMgr).UserType(InternalName))) {
        set nam=$replace(nam,"%", ..PercentClassReplace())
        if default{
            set nam=$translate(nam,".","/")
        }
        #; If match ends in '`' character use UDL/CLS format rather than XML format
        return $translate(found_nam_"."_$zconvert(ext, "l"),"\","/")
    }

    if (default){
        quit $translate($get(found)_$translate(nam,"%.","_/")_"."_$zconvert(ext,"l"),"\","/")
    } else {
        quit $translate($get(found)_nam_"."_$zconvert(ext,"l"),"\","/")
    }
}

/*
	NameToInternalName(name): given a Unix-style slash path relative to repo root, 
	returns the internal name for that file (e.g., cls/SourceControl/Git/Utils.cls -> SourceControl.Git.Utils.CLS)
*/
ClassMethod NameToInternalName(Name, IgnorePercent = 1, IgnoreNonexistent = 1, Verbose As %Boolean = 0) As %String
{
    set InternalName=""
    set Deleted = 0
    set context = ##class(SourceControl.Git.PackageManagerContext).%Get()
    if (context.IsInGitEnabledPackage) {
        if ($zconvert(Name,"U")'[$zconvert(context.Package.Root,"U")) {
            set Name = ##class(%File).NormalizeFilename(context.Package.Root_Name)
        }
    } elseif ($zconvert(Name,"U")'[$zconvert($$$SourceRoot,"U")) {
        set Name = ##class(%File).NormalizeFilename(..TempFolder()_Name)
    }
    if (##class(%File).Exists(Name)) {
        new %SourceControl //don't trigger source hooks with this test load to get the Name
        set sc=$system.OBJ.Load(Name,"-d",,.outName,1)
        if (($data(outName)=1) || ($data(outName) = 11 && ($order(outName(""),-1) = $order(outName(""))))) && ($zconvert(..Type(outName),"U") '= "CSP") {
            //only set if a single Name was returned ... ignore multi-item files
            set InternalName=outName
            if (context.IsInGitEnabledPackage) {
                // Don't need mappings!
                return ..NormalizeInternalName(InternalName)
            }
        }
    } else {
        // check for file in uncommitted queue
        &sql(SELECT internalName into :InternalName FROM SourceControl_Git.Change where ItemFile = :Name)
        if (SQLCODE = 100) {
            set InternalName = ""
        } else{
            set Deleted = 1
        }
    }
    if (InternalName="") {
        set name=$extract(Name,$length($$$SourceRoot)+1,*)
        set name=$replace(name,"\","/")	// standardize slash direction

        set nam = name
        
        set queryary=$query($$$SourceMapping(""),-1,dir), mappingsSubscript = $qsubscript(queryary,4)
        set subscript=$qsubscript(queryary,5), coverage = $qsubscript(queryary, 6)
        set bestMatch = $lb(subscript, coverage, dir)
        set bestScore = 0
        set currScore = 0
        while (queryary'="")&&(mappingsSubscript="mappings") {
            set nam = $extract(name, $length(dir)+1, *)
            if ($zconvert(subscript, "U") = $zconvert($piece(name, ".", *), "U")) {
                set extScore = 1
            } elseif (subscript = "/CSP/") {
                set extScore = 1
            } else {
                set extScore = 0
            }

            if ((dir["/")&&(dir=$extract(name, 1, $length(dir)))) {
                set pathScore = 1
            } else {
                set pathScore = 0  
            }

            if (coverage = "*") {
                set covScore = 1
            } elseif ($extract($translate(nam, "/", "."), 1, ($length(coverage)+1)) = (coverage_".")) {
                set covScore = 2
            } elseif (subscript = "/CSP/") {
                // Normalize coverage to start/end with slash
                set coverage = $case($extract(coverage),"/":"",:"/")_coverage_$case($extract(coverage,*),"/":"",:"/")
                set covScore = pathScore
            } else {
                set covScore = 0
            }

            set currScore = (extScore*100) + (pathScore*10) + covScore

            if (currScore > bestScore){
                set bestScore = currScore
                set bestMatch = $lb(subscript, coverage, dir)
            } elseif ((currScore = bestScore) && currScore>=111) {
                // There are 4 cases here - 
                // 1. Coverage is more specific in one and Path is the same.
                // 2. Path is more specific in one and Coverage is the same.
                // 3. Coverage is more specific in one while Path is more specific in the other.
                // 4. Both are more specific in one. 
                // Coverage has higher priority.
                // Note that a file extension has no notion of specificity. 
                // Specificity, for both Coverage and Path, is defined as being directly proportional to the length of the string.

                set covSpecific = 0, pathSpecific = 0
                
                if ($length(coverage) > $length($listget(bestMatch, 2))){
                    set bestMatch = $lb(subscript, coverage, dir)
                } elseif ($length(coverage) = $length($listget(bestMatch, 2))){
                    if ($length(dir) > $length($listget(bestMatch, 3))){
                        set bestMatch = $lb(subscript, coverage, dir)
                    }
                }
            }

            set queryary=$query(@queryary,-1,dir)
            if (queryary="") {
                quit
            }
            set mappingsSubscript = $qsubscript(queryary,4), subscript=$qsubscript(queryary,5), coverage = $qsubscript(queryary, 6)
        }

        if (bestScore >= 111){
            set ext = $listget(bestMatch,1)
            set dir = $listget(bestMatch, 3)
            set nam = $extract(name, $length(dir)+1, *)
        }

        if ($get(ext)="/CSP/") {
            //loop through to find if any subscripts of /CSP/ match
            set cspapp = $order($$$SourceMapping("/CSP/",""),-1,subdir)
            if (cspapp'="*"){
                do {
                    if $extract(name,1,$length(subdir))=subdir {
                        set InternalName=cspapp_$replace(name,subdir,"/")
                        quit
                    }
                    set cspapp = $order($$$SourceMapping("/CSP/",cspapp),-1,subdir)
                } while cspapp'="*"
            }
            if InternalName="" {
                //Internal Name is just the remainder after the subdirectory was removed and the leading "/" is added back
                set InternalName="/"_nam
            }
            if ($length(InternalName,"/")=2) {
                //this was a file dropped directly under /cspapp/ so treat it as a non-mapped file
                set InternalName = ""
            }
        }
        if $data(ext)=0 {
            if (Verbose){
                write !
                if (bestScore#100 = 0){
                    write !, "No mapping with a matching coverage found for file "_name
                }
                if (((bestScore\10)#10) = 0){
                    write !, "No mapping with a matching path found for file "_name
                }
                if ((bestScore\100) = 0){
                    write !, "No mapping with a matching extension found for file "_name
                }
            }
            quit ""
        }
        set fileExt=$zconvert(ext,"L")
        if (InternalName="") {
            //take our best guess based on the document extension mapped to that subdirectory
            set nam=$piece(nam,".",1,*-1)
            set nam=$replace(nam, ..PercentClassReplace(), "%")
            set nam=$translate(nam,"/",".")
            set InternalName=nam_"."_fileExt
            if (fileExt="cls") {
                // special handling for possible collissions between % and non-% classes of the same name
                set alternateInternalName="%"_InternalName
                set primaryExists=##class(%RoutineMgr).Exists(InternalName), alternateExists=##class(%RoutineMgr).Exists(alternateInternalName)
                if ('primaryExists)&&(alternateExists) { set InternalName=alternateInternalName }	// it must have been a %-class as one by that name exists
                if (primaryExists)&&(alternateExists) { quit "" }	//indeterminate as the class exists in % and non-% form in the DB
            }
        }
    }
    if ((IgnorePercent)&&($extract(InternalName)="%")) { set InternalName = "" }	// don't return a result for % items if instructed to ignore them
    if ((IgnoreNonexistent)&&('##class(%RoutineMgr).Exists(InternalName))&&('Deleted)) { set InternalName = "" }	// only return item names which exist in the DB
    quit ..NormalizeInternalName(InternalName)
}

ClassMethod OutputConfigureMessage()
{
    if '..IsNamespaceInGit() {
        write !!,"NOTE: To configure settings for git-source-control, run the following command: "
        write !, "do ##class(SourceControl.Git.API).Configure()",!
    }
}

ClassMethod Localize()
{
    // Ensure we don't fall back to defaults due to lack of en-us or the default language.
    merge ^IRIS.Msg("Studio","en-us") = ^IRIS.Msg("Studio","en")
    if $$$DefaultLanguage '= "en" {
        merge ^IRIS.Msg("Studio",$$$DefaultLanguage) = ^IRIS.Msg("Studio","en")
    }
}

ClassMethod GetSourceControlInclude() As %String
{
    quit $select(##class(%Library.EnsembleMgr).IsEnsembleInstalled():
        "<script type=""text/javascript"" src=""/isc/studio/templates/ensemble/Ens_SourceControl.js""></script>",
        1: "")
}

ClassMethod BuildCEInstallationPackage(ByRef destination As %String) As %Status
{
    #define sourcedir $System.Util.InstallDirectory()_"devuser/studio/templates/gitsourcecontrol/"
    #define sourcedirstr ##Quote($$$sourcedir)
    #define exportGBLString "||GitSourceControlProjectExport"
    #define exportGBLDoc $$$exportGBLString_".GBL"
    #define exportGBL ##Expression("^"_$$$exportGBLString)
    #define exportGBLName $Name($$$exportGBL)
    #define exportGBLNameQ ##Quote("^"_$$$exportGBLString)

    new %sourcedirstr
    set sc = $$$OK
    try {
        set projectName = "GitSourceControl_CE"
        set exportSpec = "/keepsource/exportversion=2016.2/diffexport"

        // Main project
        set destination = $Get(destination,##class(%Library.File).NormalizeFilename(projectName_".xml"))
        if ##class(%Studio.Project).%ExistsId(projectName) {
            $$$ThrowOnError(##class(%Studio.Project).%DeleteId(projectName))
        }
        set project = ##class(%Studio.Project).%New()
        set project.Name = projectName
        $$$ThrowOnError($System.OBJ.GetPackageList(.classes,"SourceControl.Git"))
        set key = ""
        for {
            set key = $Order(classes(key))
            quit:key=""
            $$$ThrowOnError(project.AddItem(key_".CLS"))
        }
        $$$ThrowOnError(project.AddItem("SourceControl.Git.INC"))
        $$$ThrowOnError(project.AddItem("%ZPM.PackageManager.Core.Singleton.CLS"))

        // /isc/studio/usertemplates project
        set sourcedir = ##class(%Library.File).NormalizeDirectory($$$sourcedir)
        set archive = ##class(%ZPM.PackageManager.Core.XDataArchive).%New(sourcedir)
        do archive.AddToProject(project)

        kill $$$exportGBL
        $$$ThrowOnError(project.ExportToStream(exportSpec,0))

        // Installer automation
        set code($i(code)) = " New %ISCName set %ISCName = ""GitSourceControlInstaller"""
        set code($i(code)) = " Set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen(""SourceControl.Git.Installer"",""Payload"",,.sc)"
        set code($i(code)) = " $$$ThrowOnError(sc)"
        set code($i(code)) = " $$$ThrowOnError($System.OBJ.LoadStream(xdata.Data,""ck/nomulticompile""))"
        do archive.GenerateInstallerCode($$$sourcedirstr,.code)
        set code($i(code)) = " Do ##class(SourceControl.Git.Utils).Localize()"
        set code($i(code)) = " Write !!"
        set code($i(code)) = " Do ##class(SourceControl.Git.Utils).OutputConfigureMessage()"
        
        // Put installer automation in class
        do $System.OBJ.Delete("SourceControl.Git.Installer.CLS","-d")
        set class = ##class(%Dictionary.ClassDefinition).%New()
        set class.Name = "SourceControl.Git.Installer"
        set class.IncludeGenerator = "%occInclude"
        set method = ##class(%Dictionary.MethodDefinition).%New()
        set method.Name = "Run"
        set method.CodeMode = "objectgenerator"
        for i=1:1:code {
            do method.Implementation.WriteLine(code(i))
        }
        do method.Implementation.WriteLine(" job ##class(%SYSTEM.OBJ).Delete(""SourceControl.Git.Installer.CLS"")")
        do class.Methods.Insert(method)

        // Put payload in XData block
        set xdata = ##class(%Dictionary.XDataDefinition).%New()
        set xdata.Name = "Payload"
        do xdata.Data.CopyFrom(project.Stream)
        do class.XDatas.Insert(xdata)

        $$$ThrowOnError(class.%Save())

        $$$ThrowOnError($System.OBJ.Export(class.Name_".CLS,"_$$$exportGBLDoc,destination,exportSpec))
        $$$ThrowOnError($System.OBJ.Delete("SourceControl.Git.Installer.CLS"))
    } catch e {
        set sc = e.AsStatus()
    }
    if $$$ISERR(sc) && '$quit {
        write !,$System.Status.GetErrorText(sc)
    }
    quit sc
}

}

