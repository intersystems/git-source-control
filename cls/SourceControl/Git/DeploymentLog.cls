Class SourceControl.Git.DeploymentLog Extends %Persistent [ Owner = {%Developer} ]
{

Property Token As %String [ InitialExpression = {$System.Util.CreateGUID()} ];

Property StartTimestamp As %TimeStamp;

Property EndTimestamp As %TimeStamp;

Property HeadRevision As %String;

Property Status As %Status;

Storage Default
{
<Data name="DeploymentLogDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Token</Value>
</Value>
<Value name="3">
<Value>StartTimestamp</Value>
</Value>
<Value name="4">
<Value>EndTimestamp</Value>
</Value>
<Value name="5">
<Value>HeadRevision</Value>
</Value>
<Value name="6">
<Value>Status</Value>
</Value>
</Data>
<DataLocation>^SourceContro22B9.DeploymentLogD</DataLocation>
<DefaultData>DeploymentLogDefaultData</DefaultData>
<IdLocation>^SourceContro22B9.DeploymentLogD</IdLocation>
<IndexLocation>^SourceContro22B9.DeploymentLogI</IndexLocation>
<StreamLocation>^SourceContro22B9.DeploymentLogS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
