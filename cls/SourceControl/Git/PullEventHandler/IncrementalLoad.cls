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
        } else {
            set compilelist(internalName) = ""
            set nFiles = nFiles + 1
            set loadSC = $$$ADDSC(loadSC,##class(SourceControl.Git.Utils).ImportItem(internalName, 1))
        }
    }

    if (nFiles = 0) {
        write !, "Nothing to compile."
        quit $$$OK
    }
    quit $system.OBJ.CompileList(.compilelist, "cukb")
}

}

