Include %syPrompt

IncludeGenerator %syPrompt

Class SourceControl.Git.Settings Extends %RegisteredObject
{

/// Path to git executable
Property gitBinPath As %String(MAXLEN = "");

/// Local git repo root folder
Property namespaceTemp As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).TempFolder()}, Required ];

/// Path to private key file for SSH remotes; if file does not exist, later prompts will help set it up with proper ownership
Property privateKeyFile As %String(MAXLEN = "") [ InitialExpression = {##class(SourceControl.Git.Utils).PrivateKeyFile()} ];

/// Event handler class for git pull
Property pullEventClass As %String(MAXLEN = 255) [ InitialExpression = {##class(SourceControl.Git.Utils).PullEventClass()}, Required ];

/// Character to replace % symbol when importing %-classes into the file systems
Property percentClassReplace As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PercentClassReplace()} ];

/// Git project settings are read-only in the web user interface
Property settingsUIReadOnly As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).SettingsUIReadOnly()} ];

/// Attribution: Git username for user ${username}
Property gitUserName As %String(MAXLEN = 255) [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserName()} ];

/// Attribution: Email address for user ${username}
Property gitUserEmail As %String(MAXLEN = 255) [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserEmail()} ];

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

/// Warn when an item has uncommitted changes in a different namespace in this instance
Property warnInstanceWideUncommitted As %Boolean [ InitialExpression = {##class(SourceControl.Git.Utils).WarnInstanceWideUncommitted()} ];

Property Mappings [ MultiDimensional ];

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
    quit $$$OK
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
    if ..basicMode = "system" {
        kill @storage@("settings", "user", $username, "basicMode")
    } else {
        set @storage@("settings", "user", $username, "basicMode") = ..basicMode
    } 

    // update value of basicUserMode to reflect the updated setting for basicMode
    set ..userBasicMode = ##class(SourceControl.Git.Utils).UserBasicMode()
    

    kill @##class(SourceControl.Git.Utils).MappingsNode()
    merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
    quit $$$OK
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
        do %code.WriteLine(" set value = inst."_property)
        set prompt = $$$comMemberKeyGet(%class.Name,$$$cCLASSproperty,property,$$$cPROPdescription)
        set promptQuoted = $$$QUOTE(prompt_":")
        set promptQuoted = $replace(promptQuoted,"${username}","'""_$Username_""'")
        do %code.WriteLine(" set response = ##class(%Library.Prompt).GetString("_promptQuoted_",.value,,,,"_defaultPromptFlag_")")
        do %code.WriteLine(" if response '= $$$SuccessResponse { quit 0 }")
        do %code.WriteLine(" set inst."_property_" = value")
        
    }
    do %code.WriteLine(" $$$ThrowOnError(inst.%Save())")
    do %code.WriteLine(" write !,""Settings saved.""")
    do %code.WriteLine(" do inst.OnAfterConfigure()")
    do %code.WriteLine(" quit 1")
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
            
            do ##class(SourceControl.Git.Utils).EmptyInitialCommit()
        } elseif (value = 2) {
            set response = ##class(%Library.Prompt).GetString("Git remote URL (note: if authentication is required, use SSH, not HTTPS):",.remote,,,,defaultPromptFlag)
            if (response '= $$$SuccessResponse) {
                quit
            }
            if (remote = "") {
                quit
            }
             // using work queue manager ensures proper OS user context/file ownership
            set workMgr = $System.WorkMgr.%New("")
            $$$ThrowOnError(workMgr.Queue("##class(SourceControl.Git.Utils).Clone",remote))
            $$$ThrowOnError(workMgr.WaitForComplete())
        }
    }
}

}
