Include (%occStatus, %occErrors, SourceControl.Git)

Class SourceControl.Git.PullEventHandler.IncrementalLoad Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Incremental Load";

Parameter DESCRIPTION = "Performs an incremental load and compile of all changes pulled.";

Method OnPull() As %Status
{
    #Dim sc As %Status = $$$OK

    // certain items must be imported before everything else.
    for i=1:1:$get(..ModifiedFiles) {
        set internalName = ..ModifiedFiles(i).internalName
        if internalName = ##class(SourceControl.Git.Settings.Document).#INTERNALNAME {
            set sc = $$$ADDSC(sc, ##class(SourceControl.Git.Utils).ImportItem(internalName, 1))
            quit
        }
    }

    set nFiles = 0
    for i=1:1:$get(..ModifiedFiles){
        set internalName = ..ModifiedFiles(i).internalName

        // Don't import the config file a second time
        continue:internalName=##class(SourceControl.Git.Settings.Document).#INTERNALNAME
        set tExternalName = ..ModifiedFiles(i).externalName

        if ((internalName = "") && (..ModifiedFiles(i).changeType '= "D")) {
            write !, tExternalName, " was not imported into the database and will not be compiled. "
        } elseif (..ModifiedFiles(i).changeType = "D") {
            #; Deleted production items will not have an internal name
            set delIndex = $select(##class(SourceControl.Git.Util.Production).ItemIsPTD(tExternalName): 1, 1: 2)
            if ((delIndex = 2) && (internalName = "")) {
                write !, tExternalName, "was not in the database.  Nothing to delete."
                continue
            }
            set:(delIndex=1) internalName = "-"_i   ;; This is a total hack because deleted production items will not have an internal name
            set delList(delIndex, internalName) = tExternalName
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

    #; First remove production items, then everything else
    write:$data(delList) !!,"Removing items..."
    for orderIndex = 1,2 {
        set item = $order(delList(orderIndex, ""), 1, tExternalName)
        while (item '= "") {
            set delSC = ..RemoveItem(item, tExternalName)
            set item = $order(delList(orderIndex, item), 1, tExternalName)
        }
    }
    if (nFiles = 0) {
        write !, "Nothing to Load."
        quit $$$OK
    }

    if $data(compilelist) {
        write !
        set sc = $$$ADDSC(sc,$system.OBJ.CompileList(.compilelist, "ckbryu"))
    }
    else {
        write !,"Nothing to Compile."
    }

    #; Deploy any PTD items
    if $data(ptdList) {
        write !,"Loading production items..."
        set start = $zhorolog
        set key = $order(ptdList(""))
        while (key '= "") {
            set sc = $$$ADDSC(sc, ##class(SourceControl.Git.Utils).ImportItem(key,1))
            set key = $order(ptdList(key))
        }
        write !,"Production items imported in ",($zhorolog-start),"s"
    }

    if $$$comClassDefined("Ens.Director") && ##class(Ens.Director).IsProductionRunning() {
        set start = $zhorolog
        write !,"Updating production... "
        set sc = $$$ADDSC(sc,##class(Ens.Director).UpdateProduction())
        write "done in ",($zhorolog-start),"s."
    }
    quit sc
}

Method RemoveItem(pInternalName, pExternalName) As %Status
{
    #Dim delSC As %Status
    set delSC = ..DeleteFile(pInternalName, pExternalName)
    if delSC {
        write !, pExternalName, " was deleted."
    } else {
        write !, "WARNING: Deletion of ", pExternalName, " failed."
        write !,?3,$system.Status.DisplayError(delSC)
    }
    quit delSC
}

Method DeleteFile(item As %String = "", externalName As %String = "") As %Status
{
    #Dim sc As %Status = $$$OK
    #Dim err As %Exception.AbstractException
    try {
        set type = $select(
            ##class(SourceControl.Git.Util.Production).ItemIsPTD(externalName): "ptd",
            1: ##class(SourceControl.Git.Utils).Type(item)
        )
        set name = ##class(SourceControl.Git.Utils).NameWithoutExtension(item)
        set settings = ##class(SourceControl.Git.Settings).%New()
        set deleted = 1
        if type = "prj" {
            set sc = $system.OBJ.DeleteProject(name)
        } elseif type = "cls" {
            if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(name) {
                write !, "Production decomposition enabled, skipping delete of production class"
            } else {
                set sc = $system.OBJ.Delete(item)
            }
        } elseif $listfind($listbuild("mac","int","inc","bas","mvb","mvi"), type) > 0 {
            set sc = ##class(%Routine).Delete(item)
        } elseif type = "csp" {
            set sc = $System.CSP.DeletePage(item)
        } elseif settings.decomposeProductions && (type = "ptd") {
            set normalizedFilePath = ##class(%File).NormalizeFilename(##class(SourceControl.Git.Utils).TempFolder()_externalName)
            set sc = ##class(%SYSTEM.Status).AppendStatus(
                ##class(SourceControl.Git.Production).RemoveItemByExternalName(normalizedFilePath,"FullExternalName"),
                ##class(%Library.RoutineMgr).Delete(item)
            )
        } elseif ##class(SourceControl.Git.Utils).UserTypeCached(item) {
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
    } catch err {
        set filename = ##class(SourceControl.Git.Utils).FullExternalName(item)
        if (filename = "") || '##class(%File).Exists(filename) {
            do ##class(SourceControl.Git.Utils).RemoveRoutineTSH(item)
            // file doesn't exist anymore despite error -- should be ok
            set sc = $$$OK
        } else {
            // Item still exists and was not deleted -- bad
            set sc = err.AsStatus()
            do err.Log()
        }
    }
    return sc
}

}
