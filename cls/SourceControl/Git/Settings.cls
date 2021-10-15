Include %syPrompt

IncludeGenerator %syPrompt

Class SourceControl.Git.Settings Extends %RegisteredObject
{

/// Path to git executable
Property gitBinPath As %String [ InitialExpression = {##class(SourceControl.Git.Utils).GitBinPath()}, Required ];

/// Local git repo root folder
Property namespaceTemp As %String [ InitialExpression = {##class(SourceControl.Git.Utils).TempFolder()}, Required ];

/// Path to private key file (for ssh remotes)
Property privateKeyFile As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PrivateKeyFile()} ];

/// Event handler class for git pull
Property pullEventClass As %String [ InitialExpression = {##class(SourceControl.Git.Utils).PullEventClass()}, Required ];

/// Attribution: Git username for user ${username}
Property gitUserName As %String [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserName()}, Required ];

/// Attribution: Email address for user ${username}
Property gitUserEmail As %String [ InitialExpression = {##class(SourceControl.Git.Utils).GitUserEmail()}, Required ];

Property Mappings [ MultiDimensional ];

Method %OnNew() As %Status
{
    Merge ..Mappings = @##class(SourceControl.Git.Utils).MappingsNode()
    quit $$$OK
}

Method %Save() As %Status
{
    set sysStorage = ##class(SourceControl.Git.Utils).InstallNamespaceStorage()
    set storage = ##class(SourceControl.Git.Utils).#Storage
    set @sysStorage@("%gitBinPath") = ..gitBinPath
    kill @sysStorage@("%gitBinExists")
    
    set @storage@("settings","namespaceTemp") = ##class(SourceControl.Git.Utils).AddSlash(..namespaceTemp)
    set @storage@("settings","user",$username,"gitUserName") = ..gitUserName

    set @storage@("settings","user",$username,"gitUserEmail") = ..gitUserEmail
    set @storage@("settings","ssh","privateKeyFile") = ..privateKeyFile
    set @storage@("settings","pullEventClass") = ..pullEventClass

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
        set sequence = $Order(orderedProperties(sequence),1,property)
        quit:sequence=""
        do %code.WriteLine(" set value = inst."_property)
        set prompt = $$$comMemberKeyGet(%class.Name,$$$cCLASSproperty,property,$$$cPROPdescription)
        set promptQuoted = $$$QUOTE(prompt_":")
        set promptQuoted = $Replace(promptQuoted,"${username}","'""_$Username_""'")
        do %code.WriteLine(" set response = ##class(%Library.Prompt).GetString("_promptQuoted_",.value,,,,"_defaultPromptFlag_")")
        do %code.WriteLine(" if response '= $$$SuccessResponse { quit 0 }")
        do %code.WriteLine(" set inst."_property_" = value")
    }
    do %code.WriteLine(" $$$ThrowOnError(inst.%Save())")
    do %code.WriteLine(" write !,""Settings saved.""")
    do %code.WriteLine(" quit 1")
}

}

