Class SourceControl.Git.DiscardState Extends (%Persistent, %JSON.Adaptor)
{

Property FullExternalName As %String(MAXLEN = "") [ Required ];

Property InternalName As %String [ Required ];

Property Contents As %Stream.GlobalCharacter(LOCATION = "^DiscardStateContents");

Property Username As %String [ Required ];

Property Branch As %String [ Required ];

Property Timestamp As %TimeStamp [ Required ];

Method RestoreToFileTree()
{
        set fileStream = ##class(%Stream.FileCharacter).%OpenId(..FullExternalName,,.sc)
        $$$ThrowOnError(sc)
        do fileStream.CopyFrom(..Contents)
        $$$ThrowOnError(fileStream.%Save())
        do ##class(SourceControl.Git.Utils).ImportItem(..InternalName, 1, 1)
        do ##class(SourceControl.Git.Utils).AddToServerSideSourceControl(..InternalName)
        $$$ThrowOnError(..%DeleteId(..%Id()))
}

ClassMethod SaveDiscardState(InternalName As %String) As %Status
{
        set discardState = ..%New()
        set discardState.FullExternalName = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
        set discardState.InternalName = InternalName

        set fileStream = ##class(%Stream.FileCharacter).%New()
        set fileStream.Filename = discardState.FullExternalName
        do fileStream.%Open()
        do discardState.Contents.CopyFrom(fileStream)
        do fileStream.%Close()
        set discardState.Username = $USERNAME
        set discardState.Branch = ##class(SourceControl.Git.Utils).GetCurrentBranch()
        set discardState.Timestamp = $zdatetime($horolog, 3)

        set st = discardState.%Save()

        quit st
}

ClassMethod DiscardStatesInBranch() As %DynamicArray
{
    set currentBranch = ##class(SourceControl.Git.Utils).GetCurrentBranch()
    set statement = "SELECT ID FROM SourceControl_Git.DiscardState WHERE branch = ?"
    set resultSet = ##class(%SQL.Statement).%ExecDirect(, statement, currentBranch)
    set discardStates = []
    while resultSet.%Next() {
        set discardState = ..%OpenId(resultSet.ID)
        do discardState.%JSONExportToString(.JSONStr)
        set discardStateObject = ##class(%DynamicAbstractObject).%FromJSON(JSONStr)
        set discardStateObject.Id = resultSet.ID
        do discardStates.%Push(discardStateObject)
    }

    quit discardStates
}

Storage Default
{
<Data name="DiscardStateDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>FullExternalName</Value>
</Value>
<Value name="3">
<Value>InternalName</Value>
</Value>
<Value name="4">
<Value>Contents</Value>
</Value>
<Value name="5">
<Value>Username</Value>
</Value>
<Value name="6">
<Value>Branch</Value>
</Value>
<Value name="7">
<Value>Timestamp</Value>
</Value>
</Data>
<DataLocation>^SourceControl22B9.DiscardStateD</DataLocation>
<DefaultData>DiscardStateDefaultData</DefaultData>
<IdLocation>^SourceControl22B9.DiscardStateD</IdLocation>
<IndexLocation>^SourceControl22B9.DiscardStateI</IndexLocation>
<StreamLocation>^SourceControl22B9.DiscardStateS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

