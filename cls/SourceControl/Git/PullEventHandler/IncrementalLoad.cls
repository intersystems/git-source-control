Include (%occStatus, %occErrors, SourceControl.Git)

Class SourceControl.Git.PullEventHandler.IncrementalLoad Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Incremental Load";

Parameter DESCRIPTION = "Performs an incremental load and compile of all changes pulled.";

Method OnPull() As %Status
{
    set sc = $$$OK

    // certain items must be imported before everything else.
    for i=1:1:$get(..ModifiedFiles) {
        if ..ModifiedFiles(i).externalName = ##class(SourceControl.Git.Settings.Document).#EXTERNALNAME {
            set sc = $$$ADDSC(sc, ##class(SourceControl.Git.Utils).ImportItem(##class(SourceControl.Git.Settings.Document).#INTERNALNAME, 1))
            quit
        }
    }

    set nFiles = 0

    for i=1:1:$get(..ModifiedFiles){
        set internalName = ##class(SourceControl.Git.Utils).NameToInternalName(..ModifiedFiles(i).externalName,,0)
        
        // Don't import the config file a second time
        continue:internalName=##class(SourceControl.Git.Settings.Document).#INTERNALNAME
        
        if ((internalName = "") && (..ModifiedFiles(i).changeType '= "D")) {
            write !, ..ModifiedFiles(i).externalName, " was not imported into the database and will not be compiled. "
        } elseif (..ModifiedFiles(i).changeType = "D") {
            set delSC = ..DeleteFile(internalName, ..ModifiedFiles(i).externalName)
            if delSC {
                write !, ..ModifiedFiles(i).externalName, " was deleted."
            } else {
                write !, "WARNING: Deletion of ", ..ModifiedFiles(i).externalName, " failed."
            }
        } else {
            set nFiles = nFiles + 1
            if (##class(SourceControl.Git.Utils).Type(internalName) = "ptd") {
                set ptdList(internalName) = ""
            } else {
                set compilelist(internalName) = ""
                set sc = $$$ADDSC(sc,##class(SourceControl.Git.Utils).ImportItem(internalName, 1))
            }
        }
    }

    if (nFiles = 0) {
        write !, "Nothing to compile."
        quit $$$OK
    }
    set sc = $$$ADDSC(sc,$system.OBJ.CompileList(.compilelist, "ck"))
    // after compilation, deploy any PTD items
    set key = $order(ptdList(""))
    while (key '= "") {
        set sc = $$$ADDSC(sc, ##class(SourceControl.Git.Utils).ImportItem(key,1))
        set key = $order(ptdList(key))
    }
    if $$$comClassDefined("Ens.Director") && ##class(Ens.Director).IsProductionRunning() {
        write !,"Updating production... "
        set sc = $$$ADDSC(sc,##class(Ens.Director).UpdateProduction())
        write "done."
    }
    quit sc
}

Method DeleteFile(item As %String = "", externalName As %String = "") As %Status
{
    try {
        set sc = $$$OK
        set type = $select(
            ##class(SourceControl.Git.Util.Production).ItemIsPTD(externalName): "ptd",
            1: ##class(SourceControl.Git.Utils).Type(item)
        )
        set name = ##class(SourceControl.Git.Utils).NameWithoutExtension(item)
        set settings = ##class(SourceControl.Git.Settings).%New()
        set deleted = 1
        if type = "prj" {
            set sc = $system.OBJ.DeleteProject(name)
        }elseif type = "cls" {
            if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(name) {
                write !, "Production decomposition enabled, skipping delete of production class"
            } else {
                set sc = $system.OBJ.Delete(item)
            }
        }elseif $listfind($listbuild("mac","int","inc","bas","mvb","mvi"), type) > 0 {
            set sc = ##class(%Routine).Delete(item)
        }elseif type = "csp" {
            set sc = $System.CSP.DeletePage(item)
        } elseif settings.decomposeProductions && (type = "ptd") {
            set normalizedFilePath = ##class(%File).NormalizeFilename(##class(SourceControl.Git.Utils).TempFolder()_externalName)
            set sc = ##class(%SYSTEM.Status).AppendStatus(
                ##class(SourceControl.Git.Production).RemoveItemByExternalName(normalizedFilePath,"FullExternalName"),
                ##class(%Library.RoutineMgr).Delete(item)
            )
        }elseif ##class(SourceControl.Git.Utils).UserTypeCached(item) {
            set sc = ##class(%Library.RoutineMgr).Delete(item)
        } else {
            set deleted = 0
        }
        
        if deleted && $$$ISOK(sc) {
            if (item '= "") {
                do ##class(SourceControl.Git.Utils).RemoveRoutineTSH(item)
                kill $$$TrackedItems(##class(%Studio.SourceControl.Interface).normalizeName(item))
            }
        } else {
            if +$system.Status.GetErrorCodes(sc) = $$$ClassDoesNotExist {
                // if something we wanted to delete is already deleted -- good!
                set sc = $$$OK
            }
        }
        // Force the catch if failing
        $$$ThrowOnError(sc)
    } catch e {
        set filename = ##class(SourceControl.Git.Utils).FullExternalName(item)
        if (filename = "") || '##class(%File).Exists(filename) {
            do ##class(SourceControl.Git.Utils).RemoveRoutineTSH(item)
            // file doesn't exist anymore despite error -- should be ok
            set sc = $$$OK
        } else {
            // Item still exists and was not deleted -- bad
            set sc = e.AsStatus()
            do e.Log() 
        }
    }
    return sc
}

}
