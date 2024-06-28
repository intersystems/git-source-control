Include (%occInclude, %occErrors, %occKeyword, %occReference, %occSAX)

Class SourceControl.Git.Util.ProductionConflictResolver Extends %RegisteredObject
{

Property logStream As %Stream.Object [ Private ];

Property productionFile As %String [ Private ];

Property productionClassname As %Dictionary.CacheClassname [ Private ];

Property errorStatus As %Status [ InitialExpression = 1, Private ];

/// API property: whether or not the conflict was resolved
Property resolved As %Boolean [ InitialExpression = 0 ];

/// API property: error message if resolved is false
Property errorMessage As %String [ Calculated ];

Method errorMessageGet() As %String
{
    If $$$ISERR(..errorStatus) {
        Do $System.Status.DecomposeStatus(..errorStatus,.components)
        If $Get(components(1,"code")) = $$$GeneralError {
            Quit $Get(components(1,"param",1))
        } Else {
            Set ex = ##class(%Exception.StatusException).CreateFromStatus(..errorStatus)
            Do ex.Log()
            Quit "an internal error occurred and has been logged."
        }
    } Else {
        Quit ""
    }
}

ClassMethod FromLog(pOutStream As %Stream.Object) As SourceControl.Git.Util.ProductionConflictResolver
{
    Set inst = ..%New()
    Try {
        Set inst.logStream = pOutStream
        Do inst.ConsumeStream()
        Do inst.Resolve()
    } Catch e {
        Set inst.resolved = 0
        Set inst.errorStatus = e.AsStatus()
    }
    Do inst.logStream.Rewind() // Finally
    Quit inst
}

Method ConsumeStream() [ Private ]
{
    Do ..logStream.Rewind()
    Do ..logStream.ReadLine()
    Set productionLine = ..logStream.ReadLine()
    Set ..productionFile = $Piece(productionLine,"Merge conflict in ",2)
    If ..productionFile = "" {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Message did not reflect merge conflict on a single file."))
    }
    If '..logStream.AtEnd {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Multiple files had merge conflicts; cannot resolve intelligently."))
    }
    Set internalName = ##class(SourceControl.Git.Utils).NameToInternalName(..productionFile)
    If ($Piece(internalName,".",*) '= "CLS") {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"File with conflict is not a class."))
    }
    Set ..productionClassname = $Piece(internalName,".",1,*-1)
    If '$$$comClassDefined(..productionClassname) && '$ClassMethod(..productionClassname,"%Extends","Ens.Production") {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"File with conflict is not an interoperability production."))
    }
}

Method Resolve() [ Private ]
{
    // If we got this far, ..productionClassname is a subclass of Ens.Production and ..productionFile is its file within the git root.
    Set code = 0
    Set code = code + ##class(SourceControl.Git.Utils).RunGitCommand("show",,.base,":1:"_..productionFile)
    Set code = code + ##class(SourceControl.Git.Utils).RunGitCommand("show",,.ours,":2:"_..productionFile)
    Set code = code + ##class(SourceControl.Git.Utils).RunGitCommand("show",,.theirs,":3:"_..productionFile)

    If code > 0 {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Unable to load base/ours/theirs for "_..productionFile))
    }

    Do ..ClassToXMLDoc(base,.baseDoc)
    Do ..ClassToXMLDoc(ours,.oursDoc)
    Do ..ClassToXMLDoc(theirs,.theirsDoc)

    Do ..ThreeWayMerge(baseDoc,oursDoc,theirsDoc,.resolved)

    Do ..XMLDocToClass(resolved)
}

Method ClassToXMLDoc(source As %Stream.Object, Output doc As %XML.Document)
{
    Set sc = $$$OK
    Kill ^||%oddDEF
    Set ^||%oddDEF(..productionClassname)=""
    Try {
        Do source.Rewind()
        While 'source.AtEnd {
            Set tTextArray($Increment(tTextArray(0))) = source.ReadLine(,.sc)
            $$$ThrowOnError(sc)
        }
        $$$ThrowOnError(##class(%Atelier.v1.Utils.TextServices).SetTextFromArray(.tTextArray,,..productionClassname,"CLS"))
        Merge classDef = ^||%oddDEF(..productionClassname)

        Set xmlStream = ##class(%Stream.TmpCharacter).%New()
        For i=1:1:$Get(classDef($$$cCLASSxdata,"ProductionDefinition",$$$cXDATAdata)) {
            Do xmlStream.WriteLine($Get(classDef($$$cCLASSxdata,"ProductionDefinition",$$$cXDATAdata,i)))
        }
        Set reader = ##class(%XML.Reader).%New()
        $$$ThrowOnError(reader.OpenStream(xmlStream))
        Set doc = reader.Document
    } Catch e {
        Set sc = e.AsStatus()
    }
    Do source.Rewind()
    Kill ^||%oddDEF
    $$$ThrowOnError(sc)
}

ClassMethod ThreeWayMerge(base As %XML.Document, theirs As %XML.Document, ours As %XML.Document, Output resolved)
{
    // TODO: actually do three-way merge
    Merge resolved = ours
}

ClassMethod BuildElementPathMap(doc As %XML.Document, Output map)
{
}

ClassMethod XMLDocToStream(document As %XML.Document, ByRef outStream)
{
    Set writer = ##class(%XML.Writer).%New()
    Set export = ##class(%Stream.TmpCharacter).%New()
    $$$ThrowOnError(writer.OutputToStream(export))
    $$$ThrowOnError(writer.Document(document))

    Set reader = ##class(%XML.Reader).%New()
    $$$ThrowOnError(reader.OpenStream(export))
    Do reader.CorrelateRoot("Ens.Config.Production")
    If 'reader.Next(.production,.sc) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Could not reimport production from resolved XML."))
    }
    $$$ThrowOnError(sc)
    $$$ThrowOnError(production.XMLExportToStream(.outStream,,"literal,indent"))
}

Method XMLDocToClass(resolved As %XML.Document)
{
    Set xData = ##class(%Dictionary.XDataDefinition).IDKEYOpen(..productionClassname,"ProductionDefinition",,.sc)
    $$$ThrowOnError(sc)
    Do xData.Implementation.Clear()
    Do ..XMLDocToStream(resolved,xData.Implementation)
    Do xData.Implementation.Rewind()
    Write !!,$ZConvert(xData.Implementation.Read(100000),"O","HTML"),!!
}

}
