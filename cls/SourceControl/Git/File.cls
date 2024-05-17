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
            // Special handling for Production Text Documents, used for Source Controlling individual Production settings
            set file = $piece(ExternalName, "/", *)
            set deployDoc = ##class(EnsLib.EDI.XML.Document).%New(ExternalName)
            set exportNotesPTDText = $ZCVT(deployDoc.GetValueAt("/Export/Document[1]/1"),"I","XML")
            set exportNotesPTD = ##class(EnsLib.EDI.XML.Document).%New(exportNotesPTDText)
            set productionClass = exportNotesPTD.GetValueAt("/Deployment/Creation/SourceProduction")
            if $extract(file,1,9) = "ProdStgs-" {
                set internalName = productionClass_"||ProductionSettings-"_productionClass_".PTD"
            } else {
                // Special case for Config Item Settings PTD, requires checking PTD CDATA for Item and Class name
                set settingsPTDText = $zconvert(deployDoc.GetValueAt("/Export/Document[2]/1"),"I","XML")
                set settingsPTD = ##class(EnsLib.EDI.XML.Document).%New(settingsPTDText)
                set itemClass = settingsPTD.GetValueAt("/Item/@ClassName")
                set itemName = settingsPTD.GetValueAt("/Item/@Name")
                set internalName = productionClass_"||"_itemName_"|"_itemClass_".PTD"
            }
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

