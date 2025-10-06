/// Has a cache of file internal/external name mappings as of LastModifiedTime.
Class SourceControl.Git.File Extends %Persistent
{

Property ExternalName As %String(MAXLEN = "") [ Required ];

Property ExternalNameHash As %String [ Calculated, SqlComputeCode = {set {*} = $System.Encryption.SHAHash(256,{ExternalName})}, SqlComputed ];

Property InternalName As %String(MAXLEN = 255) [ Required ];

Property LastModifiedTime As %String [ Required ];

Index InternalName On InternalName;

Index ExternalNameHash On ExternalNameHash [ Unique ];

ClassMethod ExternalNameToInternalName(ExternalName As %String) As %String
{
    set internalName = ""
    if ##class(%File).Exists(ExternalName) {
        set lastModified = ##class(%Library.File).GetFileDateModified(ExternalName)
        set hash = $System.Encryption.SHAHash(256,ExternalName)
        if ..ExternalNameHashExists(hash,.id) {
            set inst = ..%OpenId(id,,.sc)
            $$$ThrowOnError(sc)
            if inst.LastModifiedTime = lastModified {
                quit inst.InternalName
            } else {
                set inst.LastModifiedTime = lastModified
            }
        } else {
            set inst = ..%New()
            set inst.ExternalName = ExternalName
            set inst.LastModifiedTime = lastModified
        }
        new %SourceControl //don't trigger source hooks with this test load to get the Name
        set sc=$system.OBJ.Load(ExternalName,"-d",,.outName,1)
        // If the test load was unsuccessful then it may be due to an unsupported
        // file type (e.g. hl7 or lut) that we may otherwise be able to handle
        if $$$ISERR(sc) {
            set outName = ..ParseFileForInternalName(ExternalName)
        }
        set itemIsPTD = 0
        if $data(outName) = 11 {
            set key = $order(outName(""))
            while (key '= "") {
                if ($zconvert($piece(outName,".",*),"U") = "PTD") {
                    set itemIsPTD = 1
                    quit
                }
                set key = $order(outName(key))
            }
        }
        if itemIsPTD && ##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
            do ##class(SourceControl.Git.Production).ParseExternalName($replace(ExternalName,"\","/"),.internalName)
        } elseif (($data(outName)=1) || ($data(outName) = 11 && ($order(outName(""),-1) = $order(outName(""))))) && ($zconvert(##class(SourceControl.Git.Utils).Type(outName),"U") '= "CSP") {
            set internalName = outName
        }
        if (internalName '= "") {
            set inst.InternalName = internalName
            $$$ThrowOnError(inst.%Save())
        }
    }
    quit internalName
}

/// Attempt to determine the internal name of a given file based on its content
/// Intended to be used in situations where $system.OBJ.Load is unable to
ClassMethod ParseFileForInternalName(fileName As %String) As %String [ Private ]
{
    Set internalName = ""
    
    Set fileExtension = $ZCONVERT($PIECE(fileName,".",*),"U")
    If (fileExtension = "HL7") {
        Set tSC = ##class(%XML.TextReader).ParseFile(fileName, .textReader)
        If ($$$ISOK(tSC)) {
            // The HL7 schema name is in the 'name' attribute of the 'Category' element
            // Example: <Category name="...">
            If (textReader.ReadStartElement("Category") && textReader.MoveToAttributeName("name")) {
                If (textReader.Value '= "") {
                    Set internalName = textReader.Value_"."_fileExtension
                }
            }
        }
    } ElseIf (fileExtension = "LUT") {
        Set tSC = ##class(%XML.TextReader).ParseFile(fileName, .textReader)
        If $$$ISOK(tSC) {
            // The lookup table name is in the 'table' attribute of any 'entry' element
            // Example: <entry table="...">
            If (textReader.ReadStartElement("entry") && textReader.MoveToAttributeName("table")) {
                If (textReader.Value '= "") {
                    Set internalName = textReader.Value_"."_fileExtension
                }
            }
        }
    }
    
    Quit internalName
}

Storage Default
{
<Data name="FileDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ExternalName</Value>
</Value>
<Value name="3">
<Value>InternalName</Value>
</Value>
<Value name="4">
<Value>LastModifiedTime</Value>
</Value>
</Data>
<DataLocation>^SourceControl.Git.FileD</DataLocation>
<DefaultData>FileDefaultData</DefaultData>
<IdLocation>^SourceControl.Git.FileD</IdLocation>
<IndexLocation>^SourceControl.Git.FileI</IndexLocation>
<StreamLocation>^SourceControl.Git.FileS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
