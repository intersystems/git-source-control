Class SourceControl.Git.OAuth2.Endpoint Extends %SerialObject
{

Property AuthURL As %String;

Property DeviceAuthURL As %String;

Property TokenURL As %String;

// TODO: Might also need a Property to describe the auth style (i.e either in the header, or in the body)

Storage Default
{
<Data name="EndpointState">
<Value name="1">
<Value>AuthURL</Value>
</Value>
<Value name="2">
<Value>DeviceAuthURL</Value>
</Value>
<Value name="3">
<Value>TokenURL</Value>
</Value>
</Data>
<State>EndpointState</State>
<StreamLocation>^SourceControl.Git7826.EndpointS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
