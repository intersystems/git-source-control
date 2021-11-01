Include (%occStatus, %occErrors, SourceControl.Git)

Class SourceControl.Git.PullEventHandler.IncrementalLoad Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Incremental Load";

Parameter DESCRIPTION = "Performs an incremental load and compile of all changes pulled.";

Method OnPull() As %Status
{
    set loadSC = $$$OK
    set nFiles = 0

    set externalName = $ORDER(..ModifiedFiles(""))
    while(externalName '= "") {
        set internalName = ..ModifiedFiles(externalName)
        if (internalName = "") {
            write externalName, " was not imported into the database and will not be compiled. ", !
        } elseif '(##class(%Library.File).Exists(##class(%Library.File).NormalizeFilename(externalName,..LocalRoot))) {
            #dim type As %String = ##class(SourceControl.Git.Utils).Type(internalName)
            #dim name As %String = ##class(SourceControl.Git.Utils).NameWithoutExtension(internalName)
            #dim deleted As %Boolean = 1
            write !

            if type = "prj" {
                set loadSC = $$$ADDSC(loadSC, $system.OBJ.DeleteProject(name))
            }elseif type = "cls" {
                set loadSC = $$$ADDSC(loadSC, $system.OBJ.Delete(internalName))
            }elseif $ListFind($ListBuild("mac","int","inc","bas","mvb","mvi","dfi"), type) > 0 {
                set loadSC = $$$ADDSC(loadSC, ##class(%Routine).Delete(internalName))
            }elseif type = "csp" {
                #dim filename = $system.CSP.GetFileName(internalName)
                if ##class(%File).Exists(filename) && '##class(%File).Delete(filename) {
                    set loadSC = $$$ADDSC(loadSC, ##class(SourceControl.Git.Utils).MakeError("Error while removing "_internalName))
                }
            } else {
                set deleted = 0
            }

            if deleted && loadSC {
                do ##class(SourceControl.Git.Utils).RemoveRoutineTSH(internalName)
            } else {
                if +$system.Status.GetErrorCodes(loadSC) '= $$$ClassDoesNotExist {
                    write "Error: could not delete ", internalName, !
                } else {
                    // if something we wanted to delete is already deleted -- good!
                    set loadSC = $$$OK
                }
            }
        } else {
            set compilelist(internalName) = ""
            set nFiles = nFiles + 1
            set loadSC = $$$ADDSC(loadSC,##class(SourceControl.Git.Utils).ImportItem(internalName, 1))
        }

        set externalName = $ORDER(..ModifiedFiles(externalName))
    }

    if (nFiles = 0) {
        write "Nothing to compile.",!
        quit $$$OK
    }
    Quit $System.OBJ.CompileList(.compilelist, "cukb")
}

}
