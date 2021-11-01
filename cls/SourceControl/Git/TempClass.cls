/// Class to test file deletion at git Pull
Class SourceControl.Git.TempClass Extends %Persistent
{

Storage Default
{
<Data name="TempClassDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
</Data>
<DataLocation>^SourceControl.Git.TempClassD</DataLocation>
<DefaultData>TempClassDefaultData</DefaultData>
<IdLocation>^SourceControl.Git.TempClassD</IdLocation>
<IndexLocation>^SourceControl.Git.TempClassI</IndexLocation>
<StreamLocation>^SourceControl.Git.TempClassS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
