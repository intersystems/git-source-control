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
    If '($$$comClassDefined(..productionClassname) && $ClassMethod(..productionClassname,"%Extends","Ens.Production")) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"File with conflict is not an interoperability production."))
    }
}

Method Resolve() [ Private ]
{
    Set filePath = ##class(SourceControl.Git.Utils).TempFolder()_..productionFile
    Set file = ##class(%Stream.FileCharacter).%OpenId(filePath,,.sc)
    $$$ThrowOnError(sc)

    Do ..ResolveStream(file) // Throws exception on failure

    $$$ThrowOnError(##class(SourceControl.Git.Utils).ImportItem(..productionClassname_".CLS",1))
    $$$ThrowOnError($System.OBJ.Compile(..productionClassname,"ck"))

    // TODO: if we add multiple resolvers, move this to the end.
    set code = ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "add", ..productionFile)
    if (code '= 0) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"git add reported failure"))
    }
    set code = ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "commit", "--no-edit")
    if (code '= 0) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"git commit reported failure"))
    }

    set code = ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "rebase", "--continue")
    if (code '= 0) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"git rebase --continue reported failure"))
    }
    
    set ..resolved = 1
}

/// Non-private to support unit testing
ClassMethod ResolveStream(stream As %Stream.Object)
{
    // File may have:
    /*
    <<<<<<< HEAD
    <Item Name="Demo7" Category="" ClassName="EnsLib.CloudStorage.BusinessOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    =======
    <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    >>>>>>> 607d1f6 (modified src/HCC/Connect/Production.cls add Demo5)
    </Item>
    */

    // If:
    // * We have one such marker (<<<<<<< / ======= / >>>>>>>)
    // * The line after >>>>>> is "</Item>"
    // Then:
    // * We can replace ======= with "</Item>"

    Set copy = ##class(%Stream.TmpCharacter).%New()
    Set markerCount = 0
    Set postCloseMarker = 0
    While 'stream.AtEnd {
        Set line = stream.ReadLine()
        Set start = $Extract(line,1,7)
        If start = "<<<<<<<" {
            Set markerCount = markerCount + 1
            Continue
        } ElseIf (start = ">>>>>>>") {
            Set postCloseMarker = 1
            Continue
        } ElseIf (start = "=======") {
            Do copy.WriteLine("  </Item>")
            Continue
        } ElseIf postCloseMarker {
            If $ZStrip(line,"<>W") '= "</Item>" {
                $$$ThrowStatus($$$ERROR($$$GeneralError,"The type of conflict encountered is not handled; user must resolve manually."))
            }
            Set postCloseMarker = 0
        }
        Do copy.WriteLine(line)
    }

    If markerCount > 1 {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Multiple conflicts found, cannot resolve automatically."))
    } ElseIf markerCount = 0 {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"No conflict markers found in file"))
    }

    $$$ThrowOnError(stream.CopyFromAndSave(copy))

    Quit 1
}

}