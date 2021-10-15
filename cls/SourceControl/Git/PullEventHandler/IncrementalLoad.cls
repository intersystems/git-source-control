Include SourceControl.Git

Class SourceControl.Git.PullEventHandler.IncrementalLoad Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Incremental Load";

Parameter DESCRIPTION = "Performs an incremental load and compile of all changes pulled.";

Method OnPull() As %Status
{
    set loadSC = $$$OK
    set nFiles = 0
    for i=1:1:$Get(..ModifiedFiles) {
        if $Data(..ModifiedFiles(i))#2 {
            set internalName = ##class(SourceControl.Git.Utils).NameToInternalName(..ModifiedFiles(i),,0) 
            if (internalName = "") {
                write files(i), " was not imported into the database and will not be compiled. ", !
            } else {
                set compilelist(internalName) = ""
                set nFiles = nFiles + 1
                set loadSC = $$$ADDSC(loadSC,##class(SourceControl.Git.Utils).ImportItem(internalName, 1))
            }
        }
    }
    
    if (nFiles = 0) {
        write "Nothing to compile.",!
        quit $$$OK
    }

    Quit $System.OBJ.CompileList(.compilelist, "cukb")
}

}

