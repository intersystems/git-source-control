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

    Do ..ClassToTree(base,.baseTree)
    Do ..ClassToTree(ours,.oursTree)
    Do ..ClassToTree(theirs,.theirsTree)

    zw baseTree,oursTree,theirsTree

    Do ..ThreeWayMerge(.baseTree,.theirsTree,.oursTree,.resolved)

    Do ..TreeToClass(.resolved)
}

Method ClassToTree(source As %Stream.Object, Output tree)
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
        Set handler=##class(%XML.ImportHandler).%New("IRIS.Temp",$$$IntHandler)
        $$$ThrowOnError(##Class(%XML.SAX.Parser).ParseStream(xmlStream,handler))

        Merge tree = @handler.DOMName@(handler.Tree)
    } Catch e {
        Set sc = e.AsStatus()
    }
    Do source.Rewind()
    Kill ^||%oddDEF(..productionClassname)
    $$$ThrowOnError(sc)
}

Method ThreeWayMerge(ByRef base, ByRef theirs, ByRef ours, Output resolved)
{
}

Method TreeToClass(ByRef tree)
{
}

}
