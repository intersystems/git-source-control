Class SourceControl.Git.DiscardState Extends (%Persistent, %JSON.Adaptor)
{

Property FullExternalName As %String(MAXLEN = "") [ Required ];

Property Name As %String [ Required ];

Property Contents As %Stream.GlobalCharacter(LOCATION = "^DiscardStateContents");

Property Username As %String [ Required ];

Property Branch As %String [ Required ];

Property Timestamp As %TimeStamp [ Required ];

Property ExternalFile As %Boolean [ Required ];

Method RestoreToFileTree()
{
    set fileStream = ##class(%Stream.FileCharacter).%New()
    set fileStream.Filename = ..FullExternalName
    $$$THROWONERROR(fileStream.CopyFrom(..Contents))
    $$$THROWONERROR(fileStream.%Save())

    if '..ExternalFile {
        do ##class(SourceControl.Git.Utils).ImportItem(..Name, 1, 1)
        do ##class(SourceControl.Git.Utils).AddToServerSideSourceControl(..Name)
    }

    $$$ThrowOnError(..%DeleteId(..%Id()))
}

ClassMethod SaveDiscardState(InternalName As %String, name As %String) As %Status
{
        set discardState = ..%New()

        // If not an IRIS file
        if (InternalName = "") {
            set externalName = ##class(%File).Construct($Get(^SYS("SourceControl","Git","settings","namespaceTemp")),name)
            set discardState.FullExternalName = externalName
            set discardState.Name = name
            set discardState.ExternalFile = 1
        } else {
            set discardState.FullExternalName = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
            set discardState.Name = InternalName
            set discardState.ExternalFile = 0
        }

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

    set query = "SELECT ID FROM SourceControl_Git.DiscardState WHERE branch = ?"
    set statement = ##class(%SQL.Statement).%New()
    set status = statement.%Prepare(query, 0)
    $$$ThrowOnError(status)
    set resultSet = statement.%Execute(currentBranch)
    if (resultSet.%SQLCODE < 0) {
        throw ##class(%Exception.SQL).CreateFromSQLCODE(resultSet.%SQLCODE,resultSet.%Message)
    }

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
<Value name="8">
<Value>Name</Value>
</Value>
<Value name="9">
<Value>ExternalFile</Value>
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
