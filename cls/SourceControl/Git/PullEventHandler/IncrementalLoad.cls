Include (%occStatus, %occErrors, SourceControl.Git)

Class SourceControl.Git.PullEventHandler.IncrementalLoad Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Incremental Load";

Parameter DESCRIPTION = "Performs an incremental load and compile of all changes pulled.";

Method OnPull() As %Status
{
    set loadSC = $$$OK
    set nFiles = 0

    for i=1:1:$get(..ModifiedFiles){
        set internalName = ..ModifiedFiles(i).internalName
        if ((internalName = "") && (..ModifiedFiles(i).changeType '= "D")) {
            write !, ..ModifiedFiles(i).externalName, " was not imported into the database and will not be compiled. "
        } elseif (..ModifiedFiles(i).changeType = "D") {
            set sc = ..DeleteFile(internalName)
            if sc {
                write !, ..ModifiedFiles(i).externalName, " was deleted."
            } else {
                write !, "WARNING: Deletion of ", ..ModifiedFiles(i).externalName, " failed."
            }
        } else {
            set compilelist(internalName) = ""
            set nFiles = nFiles + 1
            set loadSC = $$$ADDSC(loadSC,##class(SourceControl.Git.Utils).ImportItem(internalName, 1))
            $$$ThrowOnError(loadSC)
        }
    }

    if (nFiles = 0) {
        write !, "Nothing to compile."
        quit $$$OK
    }
    quit $system.OBJ.CompileList(.compilelist, "cukb")
}

Method DeleteFile(item As %String)
{
    set type = ##class(SourceControl.Git.Utils).Type(item)
    if (type = "cls") {
        quit $System.OBJ.Delete(item)
    } elseif (type = "csp") {
        quit $System.CSP.DeletePage(item)
    } else {
        quit ##class(%Library.RoutineMgr).Delete(item)
    }
}

}

