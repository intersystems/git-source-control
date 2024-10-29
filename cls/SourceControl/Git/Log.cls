Class SourceControl.Git.Log Extends %Persistent [ Owner = {%Developer} ]
{

Property TimeStamp As %TimeStamp [ InitialExpression = {$zdt($h,3)} ];

Property Username As %String(MAXLEN = 128) [ InitialExpression = {$Username} ];

Index Username On Username [ Type = bitmap ];

Property LogStream As %Stream.GlobalCharacter;

Property ErrorStream As %Stream.GlobalCharacter;

/// Handy as a property in case this table is mapped
Property Namespace As %String [ InitialExpression = {$Namespace} ];

Index Namespace On Namespace [ Type = bitmap ];

Property Command As %List;

ClassMethod CommandLogicalToDisplay(command As %List) As %String
{
    If (command = "") {
        Quit ""
    }
	Quit "git "_$ListToString(command," ")
}

ClassMethod CommandBuildValueArray(command As %List, ByRef valueArray) As %Status
{
	Set pointer = 0
	While $ListNext(command,pointer,element) {
		Set valueArray(element) = ""
	}
	Quit $$$OK
}

Index CommandElements On Command(KEYS) [ Type = bitmap ];

Property ReturnCode As %Integer;

Property Source As %String [ InitialExpression = {##class(SourceControl.Git.Log).DeriveSource()} ];

Index Source On Source [ Type = bitmap ];

ClassMethod Create(log As %Stream.Object = "", err As %Stream.Object = "", ByRef args, returnCode As %Integer = 0, source As %String = "")
{
    Try {
        Set inst = ..%New()
        If $IsObject($Get(log)) {
            Do log.Rewind()
            Do inst.LogStream.CopyFromAndSave(log)
            Do log.Rewind()
        }
        If $IsObject($Get(err)) {
            Do err.Rewind()
            Do inst.ErrorStream.CopyFromAndSave(err)
            Do err.Rewind()
        }
        Set fullCommand = ""
        Set key = ""
        For {
            Set key = $Order(args(key),1,data)
            Quit:key=""
            Set fullCommand = fullCommand _ $ListBuild(data)
        }
        Set inst.Command = fullCommand
        Set inst.ReturnCode = returnCode
        If source '= "" {
            Set inst.Source = source
        }
        $$$ThrowOnError(inst.%Save())
    } Catch e {
        Do e.Log()
    }
}

ClassMethod DeriveSource() As %String
{
    Try {        
        If '$IsObject($Get(%request))#2 {
            Return "Studio"
        }
        If %request.UserAgent [ "Code/" {
            Return "VSCode WebView"
        } ElseIf (%request.UserAgent [ "node-fetch") {
            Return "VSCode API / Menu"
        } Else {
            Return "Management Portal"
        }
    } Catch e {
        Return "Unknown"
    }
}

Storage Default
{
<Data name="LogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TimeStamp</Value>
</Value>
<Value name="3">
<Value>Username</Value>
</Value>
<Value name="4">
<Value>LogStream</Value>
</Value>
<Value name="5">
<Value>ErrorStream</Value>
</Value>
<Value name="6">
<Value>Namespace</Value>
</Value>
<Value name="7">
<Value>Command</Value>
</Value>
<Value name="8">
<Value>ReturnCode</Value>
</Value>
<Value name="9">
<Value>Source</Value>
</Value>
</Data>
<DataLocation>^SourceControl.Git.LogD</DataLocation>
<DefaultData>LogDefaultData</DefaultData>
<IdLocation>^SourceControl.Git.LogD</IdLocation>
<IndexLocation>^SourceControl.Git.LogI</IndexLocation>
<Property name="%%CLASSNAME"/>
<Property name="%%ID"/>
<Property name="Command"/>
<Property name="ErrorStream"/>
<Property name="LogStream"/>
<Property name="Namespace"/>
<Property name="ReturnCode"/>
<Property name="Source"/>
<Property name="TimeStamp"/>
<Property name="Username"/>
<SQLMap name="IDKEY"/>
<StreamLocation>^SourceControl.Git.LogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

