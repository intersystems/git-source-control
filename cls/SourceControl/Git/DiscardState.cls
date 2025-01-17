Class SourceControl.Git.DiscardState Extends (%Persistent, %JSON.Adaptor)
{

Property FullExternalName As %String(MAXLEN = "") [ Required ];

Property Name As %String [ Required ];

Property Contents As %Stream.GlobalCharacter(LOCATION = "^SourceControl.Git.DiscardS");

Property Username As %String [ Required ];

Property Branch As %String [ Required ];

Property Timestamp As %TimeStamp [ Required ];

Property ExternalFile As %Boolean [ Required ];

// Boolean tracking whether or not file was deleted as part of change

Property Deleted As %Boolean;

Index BranchMap On Branch [ Type = bitmap ];

Method RestoreToFileTree()
{
    // Make sure directory for file exists
    set dir = ##class(%File).GetDirectory(..FullExternalName)
    if ('##class(%File).DirectoryExists(dir)) {
        do ##class(%File).CreateDirectoryChain(dir)
    }

    if (..Deleted) {
        do ##class(%File).Delete(..FullExternalName)
    } else {
    
        // Recreate File
        set fileStream = ##class(%Stream.FileCharacter).%New()
        set fileStream.Filename = ..FullExternalName
        $$$ThrowOnError(fileStream.CopyFrom(..Contents))
        $$$ThrowOnError(fileStream.%Save())

        // Add file to source-control / IRIS
        if '..ExternalFile {
            do ##class(SourceControl.Git.Utils).ImportItem(..Name, 1, 1, 1)
            do ##class(SourceControl.Git.Utils).AddToServerSideSourceControl(..Name)
        }
    }

    // Delete discard record
    $$$ThrowOnError(..%DeleteId(..%Id()))
}

ClassMethod SaveDiscardState(InternalName As %String, name As %String) As %Status
{
        set discardState = ..%New()
        
        if (InternalName = "") {
            // If not in IRIS
            set externalName = ##class(%File).Construct(##class(SourceControl.Git.Utils).DefaultTempFolder(),name)
            set discardState.FullExternalName = externalName
            set discardState.Name = name
            set discardState.ExternalFile = 1
        } else {
            set discardState.FullExternalName = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
            set discardState.Name = InternalName
            set discardState.ExternalFile = 0
        }
        // Copy over file contents
        if (##class(%File).Exists(discardState.FullExternalName)) {
            set fileStream = ##class(%Stream.FileCharacter).%New()
            set fileStream.Filename = discardState.FullExternalName
            do fileStream.%Open()
            do discardState.Contents.CopyFrom(fileStream)
            do fileStream.%Close()
        } else {
            set discardState.Deleted = 1
            do discardState.Contents.Write("Deleted File")
        }

        // Save extra information
        set discardState.Username = $USERNAME
        set discardState.Branch = ##class(SourceControl.Git.Utils).GetCurrentBranch()
        set discardState.Timestamp = $zdatetime($horolog, 3)

        set st = discardState.%Save()

        quit st
}

ClassMethod DiscardStatesInBranch() As %DynamicArray
{
    set currentBranch = ##class(SourceControl.Git.Utils).GetCurrentBranch()

    // Use embedded SQL for backwards compatability
    &sql(DECLARE DiscardCursor CURSOR FOR SELECT ID into :id from SourceControl_Git.DiscardState WHERE branch = :currentBranch)
    &sql(OPEN DiscardCursor)
        throw:SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
    &sql(FETCH DiscardCursor)
    set discardStates = []
    while(SQLCODE = 0) {
        set discardState = ..%OpenId(id)
        do discardState.%JSONExportToString(.JSONStr)
        set discardStateObject = ##class(%DynamicAbstractObject).%FromJSON(JSONStr)
        set discardStateObject.Id = id
        do discardStates.%Push(discardStateObject)
        &sql(FETCH DiscardCursor)
    }
    &sql(CLOSE DiscardCursor)

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
<Value name="10">
<Value>Deleted</Value>
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
