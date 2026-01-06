Include (%occInclude, %occErrors, %occKeyword, %occReference, %occSAX)

Class SourceControl.Git.Util.ResolutionManager Extends %RegisteredObject
{

Property logStream As %Stream.Object [ Private ];

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
    } Catch e {
        Set inst.resolved = 0
        Set inst.errorStatus = e.AsStatus()
    }
    Do inst.logStream.Rewind() // Finally
    Quit inst
}

Method ConsumeStream() [ Private ]
{
    Set conflicts = 0
    Do ..logStream.Rewind()
    Do ..logStream.ReadLine()
    while '..logStream.AtEnd {
        Set conflictLine = ..logStream.ReadLine()
        If $Extract(conflictLine,1,8) = "CONFLICT" {
            Set conflicts($i(conflicts)) = $Piece(conflictLine,"Merge conflict in ",2)
        }
    }
    If (conflicts = 0) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Message did not reflect merge conflict on a single file."))
    }
    For i=1:1:conflicts {
        Set targetFile = conflicts(i)
        Write !,"Attempting intelligent auto-merge for: "_targetFile
        Set internalName = ##class(SourceControl.Git.Utils).NameToInternalName(targetFile)
        If ($Piece(internalName,".",*) '= "CLS") {
            $$$ThrowStatus($$$ERROR($$$GeneralError,"File with conflict is not a class."))
        }

        Set targetClass = $Piece(internalName,".",1,*-1)
        If '$$$comClassDefined(targetClass) {
            $$$ThrowStatus($$$ERROR($$$GeneralError,"File with conflict not a known class."))
        }
        
        Set resolverClass = $Select(
            $classmethod(targetClass,"%Extends","Ens.Production"):"SourceControl.Git.Util.ProductionConflictResolver",
            $classmethod(targetClass,"%Extends","Ens.Rule.Definition"):"SourceControl.Git.Util.RuleConflictResolver",
            1:""
        )

        If (resolverClass = "") {
            $$$ThrowStatus($$$ERROR($$$GeneralError,"File with conflict not a class type that supports automatic resolution."))
        }

        do ..ResolveClass(targetClass, targetFile, resolverClass)

        set code = ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "add", targetFile)
        if (code '= 0) {
            $$$ThrowStatus($$$ERROR($$$GeneralError,"git add reported failure"))
        }
    }

    set code = ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "commit", "--no-edit")
    if (code '= 0) {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"git commit reported failure"))
    }

    set code = ##class(SourceControl.Git.Utils).RunGitWithArgs(.errStream, .outStream, "rebase", "--continue")
    if (code '= 0) {
        // Could hit a second+ conflict in the same rebase; attempt to resolve the next one too.
        set resolver = ..FromLog(outStream)
        set ..resolved = resolver.resolved
        set ..errorStatus = resolver.errorStatus
    } else {
        set ..resolved = 1
    }
}

Method ResolveClass(className As %String, fileName As %String, resolverClass As %Dictionary.Classname) [ Private ]
{
    Set filePath = ##class(SourceControl.Git.Utils).TempFolder()_fileName
    Set file = ##class(%Stream.FileCharacter).%OpenId(filePath,,.sc)
    $$$ThrowOnError(sc)

    Set resolver = $classmethod(resolverClass,"%New")
    Do resolver.ResolveStream(file) // Throws exception on failure

    $$$ThrowOnError(##class(SourceControl.Git.Utils).ImportItem(className_".CLS",1))
    $$$ThrowOnError($System.OBJ.Compile(className,"ck"))
}

}
