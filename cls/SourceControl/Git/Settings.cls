Include %syPrompt

IncludeGenerator %syPrompt

Class SourceControl.Git.Settings Extends %RegisteredObject
{

/// Path to git executable
Property gitBinPath As %String(MAXLEN = "");

/// Local git repo root directory
Property namespaceTemp As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).TempFolder()}, Required ];

/// Path to private key file for SSH remotes; if file does not exist, later prompts will help set it up with proper ownership
Property privateKeyFile As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).PrivateKeyFile()} ];

/// Event handler class for git pull
Property pullEventClass As %String(MAXLEN = 255) [ InitialExpression = {##class(SourceControl.Git.Utils).PullEventClass()}, Required ];

/// Character to replace % symbol when importing %-classes into the file systems
Property percentClassReplace As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PercentClassReplace()} ];

/// Git project settings are read-only in the web user interface
Property settingsUIReadOnly As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).SettingsUIReadOnly()} ];

/// Interoperability productions are source-controlled under separate files for each configuration item
Property decomposeProductions As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).DecomposeProductions()} ];

/// Allow editing a decomposed production class in an IDE
Property decomposeProdAllowIDE As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).DecomposeProdAllowIDE()} ];

/// Attribution: Git username for user ${username}
Property gitUserName As %String(MAXLEN = 255) [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserName()} ];

/// Attribution: Email address for user ${username}
Property gitUserEmail As %String(MAXLEN = 255) [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserEmail()} ];

/// URL for git remote
Property gitRemoteURL As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).GetConfiguredRemote()} ];

/// Type of git remote (SSH or HTTPS (Only with OAuth))
Property gitRemoteType As %String(VALUELIST = ",HTTPS,SSH") [ InitialExpression = {##class(SourceControl.Git.Settings).GetRemoteType(##class(SourceControl.Git.Utils).GetConfiguredRemote())} ];

/// Whether mapped items should be read-only, preventing them from being added to source control
Property mappedItemsReadOnly As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).MappedItemsReadOnly()} ];

/// Whether basic mode should be enabled for user ${username}, greatly simplifying the functionality of the package, requiring no knowledge of git
Property basicMode As %String [ InitialExpression = {##class(SourceControl.Git.Utils).BasicMode()} ];

/// A read-only setting used to display the basic mode setting that is chosen in the settings page
Property userBasicMode As %String [ InitialExpression = {##class(SourceControl.Git.Utils).UserBasicMode()} ];

/// The system's default mode. If true, the system defaults to basic mode
Property systemBasicMode As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).SystemBasicMode()} ];

/// Branch from which Sync will merge changes, in basic mode
Property defaultMergeBranch As %String [ InitialExpression = {##class(SourceControl.Git.Utils).DefaultMergeBranch()} ];

/// Compile using the configured pull event handler when "Import All" is run
Property compileOnImport As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).CompileOnImport()} ];

/// Define a namespace-level web application allowing access to multiple git repos across separate namespaces
Property namespaceLevelGitWebApp As %Boolean [ InitialExpression = {##class(SourceControl.Git.Settings).HasNamespaceWebApp()} ];

/// Warn when an item has uncommitted changes in a different namespace in this instance
Property warnInstanceWideUncommitted As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).WarnInstanceWideUncommitted()} ];

/// The name of the environment (DEVELOPMENT, TEST, LIVE)
Property environmentName As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).EnvironmentName()} ];

/// Whether the branch should or should not be locked down from changing namespaces
Property lockBranch As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).LockBranch()} ];

/// Whether we are using OAuth for https
Property OAuth As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).UsingOAuth()} ];

/// (Optional) A namespace-specific string that may be included in mapping configurations as <token> to support multi-namespace repositories
Property mappingsToken As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).MappingsToken()} ];

Property Mappings [ MultiDimensional ];

Property favoriteNamespaces As %DynamicArray;

Method %OnNew() As %Status
{
    set mappingsNode = ##class(SourceControl.Git.Utils).MappingsNode()
    if '$data(@mappingsNode) {
        do ##class(SourceControl.Git.Utils).SetDefaultMappings(mappingsNode)
    }
    merge ..Mappings = @mappingsNode
    set gitBinPath = ##class(SourceControl.Git.Utils).GitBinPath(.isDefault)
    if ('isDefault) {
        set ..gitBinPath = gitBinPath
    }
    set ..favoriteNamespaces = ##class(SourceControl.Git.Utils).FavoriteNamespaces()
    quit $$$OK
}

Method SaveWithSourceControl() As %Status
{
    set sc = $$$OK
    #dim %SourceControl As %Studio.SourceControl.Interface
    if '$isobject($get(%SourceControl)) {
        new %SourceControl
        do ##class(%Studio.SourceControl.Interface).SourceControlCreate($username)
    }
    set gitDir = ##class(%File).NormalizeDirectory(..namespaceTemp)_".git"
    set skipSourceControl = '##class(%File).DirectoryExists(gitDir)
    $$$QuitOnError(..%Save())
    set internalName = ##class(SourceControl.Git.Settings.Document).#INTERNALNAME
    set settingsDoc = ##class(SourceControl.Git.Settings.Document).%New(internalName)
    $$$QuitOnError(settingsDoc.Load()) // reload doc to update timestamps
    if 'skipSourceControl {
        // Source control settings naively by only calling OnAfterSave hooks
        // Future enhancement: add full source control support with settings UI
        if (##class(%Studio.SourceControl.Interface).SourceControlClassGet() = ##class(SourceControl.Git.Extension).%ClassName(1)) {
            if '##class(SourceControl.Git.Utils).IsInSourceControl(internalName) {
                set sc = ##class(SourceControl.Git.Utils).AddToSourceControl(internalName)
                $$$QuitOnError(sc)
            }
        }
        if ($IsObject($get(%SourceControl))) {
            $$$QuitOnError(%SourceControl.OnAfterSave(internalName))
        }
    }
    quit sc
}

Method %Save() As %Status
{
    set sc = ..%ValidateObject()
    if $$$ISERR(sc) {
        quit sc
    }

    set storage = ##class(SourceControl.Git.Utils).#Storage
    try {
        set sysStorage = ##class(SourceControl.Git.Utils).%SYSNamespaceStorage()
        kill @sysStorage@("%gitBinPath")
        if (..gitBinPath '= "") {
            set @sysStorage@("%gitBinPath") = ..gitBinPath
        }

        // Also put in local namespace storage to avoid permissions issues
        kill @storage@("settings","gitBinPath")
        set @storage@("settings","gitBinPath") = ..gitBinPath
    } catch e {
        // no-op; user might not have privileges.
    }
    kill ^||GitVersion
    
    set ..namespaceTemp = ##class(%Library.File).NormalizeDirectory(..namespaceTemp)
    set @storage@("settings","namespaceTemp") = ..namespaceTemp
    set workMgr = $System.WorkMgr.%New("")
    $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Settings).CreateNamespaceTempFolder"))
    $$$ThrowOnError(workMgr.WaitForComplete())

    set @storage@("settings","user",$username,"gitUserName") = ..gitUserName

    set @storage@("settings","user",$username,"gitUserEmail") = ..gitUserEmail
    set @storage@("settings","ssh","privateKeyFile") = ..privateKeyFile
    set @storage@("settings","pullEventClass") = ..pullEventClass
    set @storage@("settings","percentClassReplace") = ..percentClassReplace
    set @storage@("settings","settingsUIReadOnly") = ..settingsUIReadOnly
    set @storage@("settings", "mappedItemsReadOnly") = ..mappedItemsReadOnly
    set @storage@("settings", "defaultMergeBranch") = ..defaultMergeBranch
    set @storage@("settings", "compileOnImport") = ..compileOnImport
    set @storage@("settings", "warnInstanceWideUncommitted") = ..warnInstanceWideUncommitted
    set @storage@("settings", "basicMode") = ..systemBasicMode
    set @storage@("settings", "environmentName") = ..environmentName
    set @storage@("settings","gitRemoteType") = ..gitRemoteType
    set @storage@("settings","gitRemoteURL") = ..gitRemoteURL
    set @storage@("settings", "lockBranch") = ..lockBranch

    if (..gitRemoteType = "HTTPS") {
        set @storage@("settings","OAuth") = ..OAuth
    } else {
        set @storage@("settings","OAuth") = 0
    }

    set @storage@("settings", "mappingsToken") = ..mappingsToken

    if ..basicMode = "system" {
        kill @storage@("settings", "user", $username, "basicMode")
    } else {
        set @storage@("settings", "user", $username, "basicMode") = ..basicMode
    } 
    try {
        do ##class(%zpkg.isc.sc.git.SystemMode).SetSystemMode(..environmentName)
    } catch e {
        // no-op; user might not have privileges.
    }

    

    // update value of basicUserMode to reflect the updated setting for basicMode
    set ..userBasicMode = ##class(SourceControl.Git.Utils).UserBasicMode()
    
    set @storage@("settings","decomposeProductions") = ..decomposeProductions
    if (..decomposeProductions & ($data(..Mappings("PTD"))<10)) {
        set ..Mappings("PTD","*") = "ptd/" // configure a default mapping for PTD items
    }
    set @storage@("settings","decomposeProdAllowIDE") = ..decomposeProdAllowIDE

    kill @##class(SourceControl.Git.Utils).MappingsNode()
    merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
    
    do ##class(%zpkg.isc.sc.git.Favorites).ConfigureFavoriteNamespaces($username, ..favoriteNamespaces)

    quit $$$OK
}

Method ToDynamicObject() As %DynamicObject
{
    // uses custom methods rather than %JSON.Adaptor because Mappings multidimensional
    // array is not supported
    set settingsJSON = {
        "pullEventClass": (..pullEventClass),
        "percentClassReplace": (..percentClassReplace),
        "Mappings": {}
    }
    do settingsJSON.%Set("decomposeProductions",..decomposeProductions,"boolean")
    set k1 = $order(..Mappings(""))
    while (k1 '= "") {
        do settingsJSON.Mappings.%Set(k1, {})
        set k2 = $order(..Mappings(k1,""))
        while (k2 '= "") {
            do settingsJSON.Mappings.%Get(k1).%Set(k2,{"directory": (..Mappings(k1,k2))})
            if $get(..Mappings(k1,k2,"NoFolders")) {
                do settingsJSON.Mappings.%Get(k1).%Get(k2).%Set("noFolders", 1, "boolean")
            }
            set k2 = $order(..Mappings(k1, k2))
        }
        set k1 = $order(..Mappings(k1))
    }
    return settingsJSON
}

Method ImportDynamicObject(pSettingsDyn As %DynamicObject)
{
    set ..pullEventClass = pSettingsDyn.%Get("pullEventClass")
    set ..percentClassReplace = pSettingsDyn.%Get("percentClassReplace")
    set ..decomposeProductions = pSettingsDyn.%Get("decomposeProductions")
    kill ..Mappings
    set mappingsDyn = pSettingsDyn.%Get("Mappings", {})
    set i1 = mappingsDyn.%GetIterator()
    while i1.%GetNext(.k1, .v1) {
        set i2 = v1.%GetIterator()
        while i2.%GetNext(.k2, .v2) {
            set ..Mappings(k1, k2) = v2.%Get("directory")
            if v2.%Get("noFolders") {
                set ..Mappings(k1, k2, "NoFolders") = 1
            } else {
                kill ..Mappings(k1, k2, "NoFolders")
            }
        }
    }
}

ClassMethod CreateNamespaceTempFolder() As %Status
{
    set storage = ##class(SourceControl.Git.Utils).#Storage
    if ('##class(%File).DirectoryExists(@storage@("settings","namespaceTemp"))){ 
        do ##class(%Library.File).CreateDirectoryChain(@storage@("settings","namespaceTemp"))
    }

    return $$$OK
}

ClassMethod Configure() As %Boolean [ CodeMode = objectgenerator ]
{
    do %code.WriteLine(" set inst = ..%New()")
    do %code.WriteLine(" do inst.RetrieveDefaults()")
    set defaultPromptFlag = $$$DisableBackupCharMask + $$$TrapCtrlCMask + $$$EnableQuitCharMask + $$$DisableHelpCharMask + $$$DisableHelpContextCharMask + $$$TrapErrorMask
    set property = ""
    for {
        set property = $$$defMemberNext(%class.Name,$$$cCLASSproperty,property)
        quit:property=""
        continue:$$$comMemberKeyGet(%class.Name,$$$cCLASSproperty,property,$$$cPROPmultidimensional)
        set sequence = $$$comMemberKeyGet(%class.Name,$$$cCLASSproperty,property,$$$cPROPsequencenumber)
        set orderedProperties(sequence) = property
    }
    set sequence = ""
    for {
        set sequence = $order(orderedProperties(sequence),1,property)
        quit:sequence=""
        continue:property="userBasicMode"
        continue:property="favoriteNamespaces"
        do %code.WriteLine(" set value = inst."_property)
        set prompt = $$$comMemberKeyGet(%class.Name,$$$cCLASSproperty,property,$$$cPROPdescription)
        set promptQuoted = $$$QUOTE(prompt_":")
        set promptQuoted = $replace(promptQuoted,"${username}","'""_$Username_""'")
        set propertyDef = ##class(%Dictionary.PropertyDefinition).%OpenId("SourceControl.Git.Settings||"_property_"")
        if ((propertyDef) && (propertyDef.Type = "%Boolean")) {
            do %code.WriteLine(" set response = ##class(%Library.Prompt).GetYesNo("_promptQuoted_",.value,,"_defaultPromptFlag_")")
        } elseif ((propertyDef) && (propertyDef.Name = "gitBinPath")) {
            do %code.WriteLine(" set valid = 0")
            do %code.WriteLine(" while ('valid) {")
            do %code.WriteLine(" set response = ##class(%Library.Prompt).GetString("_promptQuoted_",.value,,,,"_defaultPromptFlag_")")
            do %code.WriteLine(" set value = $zstrip(value,""<>W"")")
            do %code.WriteLine(" set status =  inst.ConfigureBinPath(.value)")
            do %code.WriteLine(" if (status) { set valid = 1 }")
            do %code.WriteLine(" }")
            do %code.WriteLine(" set gitExists = ##class(SourceControl.Git.Utils).GitBinExists(.version)")
            do %code.WriteLine(" if (+$PIECE(version,""version "",2))<2.31 && gitExists{")
            do %code.WriteLine(" write !!, ""WARNING: You are using an older version of git which is not compatible with git-source-control. Please upgrade to git version 2.31.0 or greater to continue""")
            do %code.WriteLine(" write !!, ""Cancelling git-source-control configuration...""")
            do %code.WriteLine(" quit")
            do %code.WriteLine(" }")
        } elseif ((propertyDef) && (propertyDef.Name = "basicMode")) {
            set basicModePromptFlag = defaultPromptFlag + $$$MatchExactArrayMask + $$$InitialDisplayMask
            do %code.WriteLine(" set list(1) = ""Yes""")
            do %code.WriteLine(" set list(2) = ""No""")
            do %code.WriteLine(" set list(3) = ""System's Default Mode""")
            do %code.WriteLine(" if inst.userBasicMode = ""system"" { set value = ""System's Default Mode""}")
            do %code.WriteLine(" elseif inst.userBasicMode = 1 { set value = ""Yes""}")
            do %code.WriteLine(" elseif inst.userBasicMode = 0 { set value = ""No""}")
            do %code.WriteLine(" set response = ##class(%Library.Prompt).GetArray("_promptQuoted_",.value,.list,,,,"_basicModePromptFlag_")")
            do %code.WriteLine(" if value = ""System's Default Mode"" { set value = ""system""}")
            do %code.WriteLine(" elseif value = ""Yes"" { set value = 1}")
            do %code.WriteLine(" elseif value = ""No"" { set value = 0}")
        } elseif ((propertyDef) && (propertyDef.Name = "environmentName")) {
            do %code.WriteLine(" set list(1) = ""DEVELOPMENT""")
            do %code.WriteLine(" set list(2) = ""TEST""")
            do %code.WriteLine(" set list(3) = ""LIVE""")
            do %code.WriteLine(" set list(4) = ""FAILOVER""")
            do %code.WriteLine(" set list(5) = """"")
            do %code.WriteLine(" set response = ##class(%Library.Prompt).GetArray("_promptQuoted_",.value,.list,,,,"_defaultPromptFlag_")")
        } elseif ((propertyDef) && (propertyDef.Name ="gitRemoteType")) {
            do %code.WriteLine(" if (inst.gitRemoteURL '= """") { set value = inst.GetRemoteType(inst.gitRemoteURL)}")
        } elseif ((propertyDef) && (propertyDef.Name = "OAuth")) {
            do %code.WriteLine(" if (inst.gitRemoteType = ""HTTPS"") {")
            do %code.WriteLine(" set value = 0")
            do %code.WriteLine(" set response = ##class(%Library.Prompt).GetYesNo("_promptQuoted_",.value,,"_defaultPromptFlag)
            do %code.WriteLine(" }")
        } else {
            do %code.WriteLine(" set response = ##class(%Library.Prompt).GetString("_promptQuoted_",.value,,,,"_defaultPromptFlag_")")
        }
        do %code.WriteLine(" if response '= $$$SuccessResponse { quit 0 }")
        do %code.WriteLine(" set value = $zstrip(value,""<>W"")")
        do %code.WriteLine(" set inst."_property_" = value")
        
    }
    do %code.WriteLine(" $$$ThrowOnError(inst.SaveWithSourceControl())")
    do %code.WriteLine(" write !,""Settings saved.""")
    do %code.WriteLine(" do inst.OnAfterConfigure()")
    do %code.WriteLine(" quit 1")
}

Method ConfigureNamespaceWebApplication()
{
    Set root = ##class(%Library.File).NormalizeDirectory(##class(SourceControl.Git.Utils).TempFolder())
    Set deleteWebApp = ..HasNamespaceWebApp(.appDirectory) && '..namespaceLevelGitWebApp
    Set createWebApp = ..namespaceLevelGitWebApp && '..HasNamespaceWebApp()
    Do ..WebAppOperation("/git/"_$Namespace_"/", createWebApp, deleteWebApp, root)
}

Method WebAppOperation(name, create As %Boolean, delete As %Boolean, root As %String) [ Private ]
{
    Set namespace = $Namespace
    New $Namespace
    Set $Namespace = "%SYS"
    If $Extract(name) = "/" {
        Set name = $Extract(name,1,*-1)
    }
    If delete {
        If ##class(Security.Applications).Exists(name) {
            $$$ThrowOnError(##class(Security.Applications).Delete(name))
            Write !,"Removed web application "_name
        }
        Quit
    }

    // These are the only things we want to coerce.
    Set props("AutheEnabled")=0 // No auth methods enabled = impossible to use
    Set props("InbndWebServicesEnabled")=0
    Set props("ServeFiles")=0
    Set props("Enabled")=1
    Set props("Name")=name
    Set props("NameSpace")=namespace
    Set props("Path")=root
    Set props("Type")=2
    Set props("Recurse")=1
    If create {
        Write !,"Creating web application: "_name_"... "
        $$$ThrowOnError(##class(Security.Applications).Create(name,.props))
        Write "done."
    } ElseIf ##class(Security.Applications).Exists(name) {
        Write !,"Web application '"_name_"' already exists."
        $$$ThrowOnError(##class(Security.Applications).Get(name,.existingProps))
        Set changes = 0
        Set key = ""
        For {
            Set key = $Order(props(key),1,value)
            Quit:key=""
            If (value '= $Get(existingProps(key))) {
                Write !,"Changing "_key_": "_$Get(existingProps(key))_" -> "_value
                Set changes = 1
            }
        }
        If changes {
            $$$ThrowOnError(##class(Security.Applications).Modify(name,.props))
            Write !,"Web application '"_name_"' updated."
        } Else {
            Write !,"No changes made to web application."
        }
    }
}

ClassMethod HasNamespaceWebApp(Output webAppDirectory) As %Boolean
{
    Set webAppDirectory = $System.CSP.GetFileName("/git/"_$Namespace_"/")
    If (webAppDirectory '= "") {
        Set webAppDirectory = ##class(%Library.File).NormalizeDirectory(webAppDirectory)
    }
    Quit (webAppDirectory '= "")
}

Method OnAfterConfigure() As %Boolean
{
    set defaultPromptFlag = $$$DisableBackupCharMask + $$$TrapCtrlCMask + $$$EnableQuitCharMask + $$$DisableHelpCharMask + $$$DisableHelpContextCharMask + $$$TrapErrorMask
    if (..privateKeyFile '= "") && '##class(%File).Exists(..privateKeyFile) {
        set value = 1
        set response = ##class(%Library.Prompt).GetYesNo("Do you wish to create a new SSH key pair?",.value,,defaultPromptFlag)
        if (response '= $$$SuccessResponse) {
            quit
        }
        if value {
            #dim workMgr As %SYSTEM.AbstractWorkMgr
             // using work queue manager ensures proper OS user context when running ssh-keygen
            set workMgr = $System.WorkMgr.%New("")
            $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Utils).GenerateSSHKeyPair"))
            $$$ThrowOnError(workMgr.WaitForComplete())
            set pubKeyName = ..privateKeyFile_".pub"
            if ##class(%File).Exists(pubKeyName) {
                set pubStream = ##class(%Stream.FileCharacter).%OpenId(pubKeyName,,.sc)
                $$$ThrowOnError(sc)
                Write !,"Public key (for use as ""deploy key"", etc.):",!
                do pubStream.OutputToDevice()
                Write !
            }
        }
    }

    do ..ConfigureNamespaceWebApplication()

    set gitDir = ##class(%File).NormalizeDirectory(..namespaceTemp)_".git"
    if '##class(%File).DirectoryExists(gitDir) {
        set list(1) = "Initialize empty repo"
        set list(2) = "Clone..."
        set list(3) = "Do nothing"
        set value = ""
        while ('+$get(value)) {
            set response = ##class(%Library.Prompt).GetMenu("No git repo exists in "_..namespaceTemp_". Choose an option:",.value,.list,,defaultPromptFlag + $$$InitialDisplayMask)
            if (response '= $$$SuccessResponse) && (response '= $$$BackupResponse) {
                return
            }
        }
        if (value = 1) {
            set settings = ##class(SourceControl.Git.Settings).%New()
            set repoRootFolder = settings.namespaceTemp
            if ($extract(repoRootFolder, $length(repoRootFolder)) = "\") || ($extract(repoRootFolder, $length(repoRootFolder)) = "/") {
                set repoRootFolder = $extract(settings.namespaceTemp, 1, $length(settings.namespaceTemp) - 1)
            }
            set repoRootFolder = $translate(repoRootFolder, "\", "/")
            do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("config",,,,"--global", "--add", "safe.directory", repoRootFolder)
             // using work queue manager ensures proper OS user context/file ownership
            set workMgr = $System.WorkMgr.%New("")
            $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Utils).Init"))
            $$$ThrowOnError(workMgr.WaitForComplete())
        } elseif (value = 2) {
            set remote = $select(..gitRemoteURL:..gitRemoteURL, 1:"")
            set response = ##class(%Library.Prompt).GetString("Git remote URL:",.remote,,,,defaultPromptFlag)
            if (response '= $$$SuccessResponse) {
                quit
            }
            if (remote = "") {
                quit
            }
            set ..gitRemoteURL = remote
            set ..gitRemoteType = ..GetRemoteType(..gitRemoteURL)
            do ..%Save()


            if ((..gitRemoteType = "HTTPS") && ('..OAuth)) {
                set value = 0
                set response = ##class(%Library.Prompt).GetYesNo("Do you want to use OAuth for your https remote",.value,,defaultPromptFlag)
                if (response '= $$$SuccessResponse) {
                    quit
                }
                set ..OAuth = value
                do ..%Save()
            }   
               

            if ((..gitRemoteType = "HTTPS") && ..OAuth) {
                set remote = ##class(SourceControl.Git.OAuth2).FixRemoteURL(remote)
                Write !, "Please navigate to the Embedded Git UI on your browser, and press ""Authenticate"" in the bottom left corner."
                Write !, "Once that process is complete, return here to verify cloning was successful"
                Write !, "*Note: You must log in to the Management Portal as the current user"

                // poll attempt count
                set try = 0
                // poll every `SLEEPTIME` seconds
                set SLEEPTIME = 5
                // stop polling after `TIMEOUT` seconds
                set TIMEOUT = 300
                While try*SLEEPTIME < TIMEOUT {
                    do ##class(SourceControl.Git.Util.CredentialManager).GetAccessToken($username, .err, .code)
                    #; if code '= 1 {
                    #;     set ^mtempdc($zh,"err") = err
                    #;     set ^mtempdc($zh,"code") = code
                    #;     $$$ThrowStatus($$$ERROR($$$GeneralError, "Unable to authenticate with OAuth"))
                    #; }
                    
                    if err = "" {
                        // token was saved successfully, exit loop
                        quit
                    }
                }
            }            

            // using work queue manager ensures proper OS user context/file ownership
            set workMgr = $System.WorkMgr.%New("")
            $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Utils).Clone",remote))
            $$$ThrowOnError(workMgr.WaitForComplete())
            // export settings file without committing
            $$$ThrowOnError(..SaveWithSourceControl())

            // Empty repo breaks Embedded Git, commit the settings file
            do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("log",,.errStream,.outStream)
            do errStream.Rewind()
            if (errStream.Read() [ "does not have any commits yet") {
                w !,"Cloned Empty Repository, committing initial source control settings",!
                $$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl(##class(SourceControl.Git.Settings.Document).#INTERNALNAME))
                $$$ThrowOnError(##class(SourceControl.Git.Utils).Commit(##class(SourceControl.Git.Settings.Document).#INTERNALNAME,"initial commit"))
            }
        }
    }
}

Method ConfigureBinPath(ByRef path As %String) As %Boolean
{
    if (path = "") { return 1 }
    // Sometimes path is quoted 
    set path = $replace(path,"""","")
    if (##class(%File).DirectoryExists(path)) {
        set gitFile = $case($$$isWINDOWS,1:"git.exe",:"git")
        set path = ##class(%File).Construct(path, gitFile)
    } 
    
    if (##class(%File).Exists(path)) {
        // no-op
    } else {
        write !, "The entered path is not a valid path, please try again"
        return 0
    }
    try {
        set sysStorage = ##class(SourceControl.Git.Utils).%SYSNamespaceStorage()
        kill @sysStorage@("%gitBinPath")
        if (..gitBinPath '= "") {
            set @sysStorage@("%gitBinPath") = path
        }
        kill ^||GitVersion
        // Get and write the version
        set gitExists = ##class(SourceControl.Git.Utils).GitBinExists(.version)
        write !, "You are now using "_version
    } catch e {
        // no-op, user may not have privileges
    }
    return 1
}

Method RetrieveDefaults() As %Boolean
{
    do ##class(%zpkg.isc.sc.git.Defaults).GetDefaultSettings(.settings)
    set iterator = settings.%GetIterator()
    while iterator.%GetNext(.key, .value) {
        set $property($this,key) = value
    }
    return $$$OK
}

Method SaveDefaults() As %Boolean
{
    set defaults = {}
    set items = $lb("gitBinPath", "pullEventClass", "percentClassReplace", "environmentName", "systemBasicMode", "defaultMergeBranch", "mappedItemsReadOnly", "compileOnImport")
    for i=1:1:$LISTLENGTH(items) {
        set property = $listget(items,i)
        do defaults.%Set(property, $property($this, property))
    }
    return ##class(%zpkg.isc.sc.git.Defaults).SetDefaultSettings(defaults)
}

ClassMethod GetRemoteType(remoteURL As %String) As %String
{
    return $select(remoteURL [ "https": "HTTPS",1:"SSH")
}

}
