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
    quit $system.OBJ.CompileList(.compilelist, "ck")
}

Method DeleteFile(item As %String) As %Status
{
    set sc = $$$OK
    set type = ##class(SourceControl.Git.Utils).Type(item)
    set name = ##class(SourceControl.Git.Utils).NameWithoutExtension(item)
    set deleted = 1
    if type = "prj" {
        set sc = $system.OBJ.DeleteProject(name)
    }elseif type = "cls" {
        set sc = $system.OBJ.Delete(item)
    }elseif $listfind($listbuild("mac","int","inc","bas","mvb","mvi"), type) > 0 {
        set sc = ##class(%Routine).Delete(item)
    }elseif type = "csp" {
        set sc = $System.CSP.DeletePage(item)
    }elseif ##class(SourceControl.Git.Utils).UserTypeCached(item) {
        set sc = ##class(%Library.RoutineMgr).Delete(item)
    } else {
        set deleted = 0
    }
    
    if deleted && $$$ISOK(sc) {
        do ##class(SourceControl.Git.Utils).RemoveRoutineTSH(item)
        kill $$$TrackedItems(##class(SourceControl.Git.Utils).NormalizeExtension(item))
    } else {
        if +$system.Status.GetErrorCodes(sc) = $$$ClassDoesNotExist {
            // if something we wanted to delete is already deleted -- good!
            set sc = $$$OK
        }
    }
    return sc
}

}
