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
