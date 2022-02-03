Include %syPrompt

IncludeGenerator %syPrompt

Class SourceControl.Git.Settings Extends %RegisteredObject
{

/// Path to git executable
Property gitBinPath As %String;

/// Local git repo root folder
Property namespaceTemp As %String [ InitialExpression = {##class(SourceControl.Git.Utils).TempFolder()}, Required ];

/// Path to private key file (for ssh remotes)
Property privateKeyFile As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PrivateKeyFile()} ];

/// Event handler class for git pull
Property pullEventClass As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PullEventClass()}, Required ];

/// Character to replace % symbol when importing %-classes into the file systems
Property percentClassReplace As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PercentClassReplace()} ];

/// Attribution: Git username for user ${username}
Property gitUserName As %String [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserName()}, Required ];

/// Attribution: Email address for user ${username}
Property gitUserEmail As %String [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserEmail()}, Required ];

Property Mappings [ MultiDimensional ];

Method %OnNew() As %Status
{
    merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
    set gitBinPath = ##class(SourceControl.Git.Utils).GitBinPath(.isDefault)
    if ('isDefault) {
        set ..gitBinPath = gitBinPath
    }
    quit $$$OK
}

Method %Save() As %Status
{
    set sysStorage = ##class(SourceControl.Git.Utils).InstallNamespaceStorage()
    set storage = ##class(SourceControl.Git.Utils).#Storage
    kill @sysStorage@("%gitBinPath")
    if (..gitBinPath '= "") {
        set @sysStorage@("%gitBinPath") = ..gitBinPath
    }
    kill ^||GitVersion
    
    set @storage@("settings","namespaceTemp") = ##class(SourceControl.Git.Utils).AddSlash(..namespaceTemp)
    if ('##class(%File).DirectoryExists(@storage@("settings","namespaceTemp"))){
        do ##class(%Library.File).CreateDirectoryChain(@storage@("settings","namespaceTemp"))
    }
    set @storage@("settings","user",$username,"gitUserName") = ..gitUserName

    set @storage@("settings","user",$username,"gitUserEmail") = ..gitUserEmail
    set @storage@("settings","ssh","privateKeyFile") = ..privateKeyFile
    set @storage@("settings","pullEventClass") = ..pullEventClass
    set @storage@("settings", "percentClassReplace") = ..percentClassReplace

    kill @##class(SourceControl.Git.Utils).MappingsNode()
    merge @##class(SourceControl.Git.Utils).MappingsNode() = ..Mappings
    quit $$$OK
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
    do %code.WriteLine(" quit 1")
}

}
