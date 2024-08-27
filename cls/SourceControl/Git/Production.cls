/// This class serves as an intermediary for managing Source Control for Productions. 
/// Included is handling for exporting Productions as individual pieces of settings
/// and importing individual item settings.
Class SourceControl.Git.Production Extends %RegisteredObject
{

/// Exports settings for a given Production and each Config Item from
/// the ProductionDefinition as separate XMLs. These are exported to 
/// the /ptd subdirectory under the client's ^Sources directory.
ClassMethod ExportProductionDefinitionShards(productionClass As %String, nameMethod As %String) As %Status
{
    // First, export Production definition omitting Config Items
    Set sc = ..ExportProductionSettings(productionClass, nameMethod)
    If $$$ISERR(sc) {
	    Return sc
    }

    // next, export each item to a separate file
    Set rs = ##class(%SQL.Statement).%ExecDirect(,
        "select Name, ClassName from Ens_Config.Item where Production = ?"
        , productionClass
    )
    Throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
    While rs.%Next() {
        Set ptdName = ""
        Set item = ##class(Ens.Config.Production).OpenItemByConfigName(productionClass _ "||" _ rs.Name _ "|" _ rs.ClassName)
        If $isobject(item) { 
            Set sc = ..ExportConfigItemSettings(productionClass, item, nameMethod)
            If $$$ISERR(sc) {
	            Return sc
            }
        }
    }
    Return $$$OK
}

/// Exports a Studio project including both the provided PTD and export notes for the PTD
ClassMethod ExportProjectForPTD(productionClass, ptdName, exportPath) As %Status
{
    set st = $$$OK
    try {
        set project = ##class(%Studio.Project).%New()
        set project.Name = $replace($replace(ptdName,".","_"),":","-")
        kill projContentsList
        set projContentsList(ptdName _ ".PTD") = ""
        $$$ThrowOnError(##class(Ens.Deployment.Utils).CreateExportNotesPTD(project.Name,productionClass,,.projContentsList,0,.exportNotesPTDName))
        // strip items from export notes that break our diff
        set st = ##class(Ens.Util.ProjectTextDocument).GetStream(.notesStream, exportNotesPTDName)
        quit:$$$ISERR(st)
        set newNotesStream = ##class(%Stream.GlobalCharacter).%New()
        while 'notesStream.AtEnd {
            set line = notesStream.ReadLine()
            if $match(line, "^<(Machine|Instance|Namespace|Username)>.*") {
                // remove these
            } elseif $match(line, "^<UTC>.*") {
                // dummy timestamp for source control hooks to work properly
                set st = newNotesStream.WriteLine("<UTC>1841-01-01 00:00:00.000</UTC>")
                quit:$$$ISERR(st)
            } else {
                set st = newNotesStream.WriteLine(line)
                quit:$$$ISERR(st)
            }
        }
		do:##class(%RoutineMgr).Exists(exportNotesPTDName_".PTD") ##class(%RoutineMgr).Delete(exportNotesPTDName_".PTD") 
        set st = ##class(Ens.Util.ProjectTextDocument).Create(newNotesStream, exportNotesPTDName, "Export Notes for export "_project.Name)
        quit:$$$ISERR(st)
        // Internal/External naming logic relies on Export Notes being added to project first. If this is changed check for dependencies
        do project.AddItem(exportNotesPTDName_".PTD")
        do project.AddItem(ptdName_".PTD")
        $$$ThrowOnError(project.%Save())
        set projContentsList(exportNotesPTDName_".PTD") = ""
        set projContentsList(project.Name_".PRJ") = ""
        $$$ThrowOnError($System.OBJ.Export(.projContentsList, exportPath, "/diffexport=1"))
    } catch err {
        set st = err.AsStatus()
    }
    if $IsObject(project) {
        set st = $$$ADDSC(st,##class(%Studio.Project).%DeleteId(project.Name))
    }
    return st
}

/// Creates and exports a PTD item for a given internal name, either a single config item
/// or the production settings.
ClassMethod ExportPTD(internalName As %String, nameMethod) As %Status
{
	Set name = $Piece(internalName,".",1,$Length(internalName,".")-1)
    Set $ListBuild(productionName, itemName) = $ListFromString(name, "||")
    Set $ListBuild(itemName, itemClassName) = $ListFromString(itemName, "|")
    If $Piece($Piece(name,"||",2),"|",2) = "" {
        Set sc = ..ExportProductionSettings(productionName, nameMethod)
    } Else {
        Set configItemName = productionName_"||"_$Piece(itemName, "Settings-", 2)_"|"_itemClassName
        Set item = ##class(Ens.Config.Production).OpenItemByConfigName(configItemName)
        Set sc = ..ExportConfigItemSettings(productionName, item, nameMethod)
    }
    Return sc
}

/// Export a single Production Config Item. For a given Ens.Config.Item, the 
/// exports the PTD for this item to the file system under the directory specified
ClassMethod ExportConfigItemSettings(productionClass As %String, item As %RegisteredObject, nameMethod As %String) As %Status
{
	Set internalName = productionClass_"||Settings-"_item.Name_"|"_item.ClassName_".PTD"
	Set externalName = $ClassMethod($$SrcCtrlCls^%buildccr, nameMethod, internalName)
	Set filename = ##class(%File).NormalizeFilename(externalName)
    set st = ##class(Ens.Deployment.Utils).CreatePTDFromItem(.item, .ptdName)
    $$$QuitOnError(st)
    set st = ..ExportProjectForPTD(productionClass, ptdName, filename)
    $$$QuitOnError(st)
    Return st
}

/// Exports the Production settings from ProductionDefinition given the Production
/// class name
ClassMethod ExportProductionSettings(productionClass As %String, nameMethod As %String) As %Status
{
	Set internalName = productionClass_"||ProductionSettings-"_productionClass_".PTD"
    Set class = ##class(%Dictionary.CompiledClass).%OpenId(productionClass)
    Set sc = ##class(Ens.Deployment.Utils).CreatePTDFromProduction(class, .ptdName)
    If $$$ISERR(sc) {
	    Return sc
    }
    Set externalName = $ClassMethod($$SrcCtrlCls^%buildccr, nameMethod, internalName)
    Set filename = ##class(%File).NormalizeFilename(externalName)
    set sc = ..ExportProjectForPTD(productionClass, ptdName, filename)
    Return sc
}

ClassMethod GetModifiedItemsBeforeSave(internalName, Location, Output modifiedItems)
{
    kill modifiedItems
    set productionName = $piece(internalName,".",1,*-1)
    if ..IsEnsPortal() {
        // If editing from SMP, get the modified items by looking at %IsModified on the items in the production in memory.
        // No way to know if an item has been added or deleted, so ignore it.
        set productionConfig = ##class(Ens.Config.Production).%OpenId(productionName)
        if $isobject(productionConfig) {
            set modifiedItem = $$$NULLOREF
            for i=1:1:productionConfig.Items.Count() {
                set item = productionConfig.Items.GetAt(i)
                if item.%IsModified() {
                    set modifiedItem = item
                    quit
                }
                for j=1:1:item.Settings.Count() {
                    set setting = item.Settings.GetAt(i)
                    if $isobject(setting) && setting.%IsModified() {
                        set modifiedItem = item
                        quit
                    }
                }
            }
            set modifiedInternalName = ""
            if $isobject(modifiedItem) {
                set modifiedInternalName = productionName _ "||Settings-" _ modifiedItem.Name _ "|" _ modifiedItem.ClassName _ ".PTD"
            } else {
                // cannot check %IsModified on production config settings because they are not actually modified at this point.
                // workaround: just assume any change not to a specific item is to the production settings
                set modifiedInternalName = productionName _ "||ProductionSettings-" _ productionName _ ".PTD"
            }
        }
        if (modifiedInternalName '= "") {
            set modifiedItems(modifiedInternalName) = "M"
        }
    } else {
        // If editing/adding/deleting from Studio, get the modified items by comparing the XDATA in Location with the XDATA in the compiled class.
        // FUTURE: implement this to support Studio
    }
    // populate data for use in OnAfterSave
    kill ^mtempsscProd($job,"modifiedItems")
    merge ^mtempsscProd($job,"modifiedItems") = modifiedItems
    // FUTURE: use a percent variable or PPG instead
    kill ^mtempsscProd($job,"items")
    set rs = ##class(%SQL.Statement).%ExecDirect(
        ,"select Name, ClassName from Ens_Config.Item where Production = ?"
        , productionName)
    $$$ThrowSQLIfError(rs.%SQLCODE, rs.%Message)
    while rs.%Next() {
        set ^mtempsscProd($job,"items",$listbuild(rs.Name, rs.ClassName)) = 1
    }
}

ClassMethod GetModifiedItemsAfterSave(internalName, Output modifiedItems)
{
    kill modifiedItems
    set productionName = $piece(internalName,".",1,*-1)
    if ..IsEnsPortal() {
        // If adding/deleting from SMP, get the modified items by comparing items in temp global with items now
        set rs = ##class(%SQL.Statement).%ExecDirect(
            ,"select Name, ClassName from Ens_Config.Item where Production = ?"
            , productionName)
        $$$ThrowSQLIfError(rs.%SQLCODE, rs.%Message)
        while rs.%Next() {
            if '$get(^mtempsscProd($job,"items", $listbuild(rs.Name, rs.ClassName))) {
                set itemInternalName = productionName _ "||Settings-" _ rs.Name _ "|" _ rs.ClassName _ ".PTD"
                set modifiedItems(itemInternalName) = "A"
            }
            kill ^mtempsscProd($job,"items", $listbuild(rs.Name, rs.ClassName))
        }
        set key = $order(^mtempsscProd($job,"items",""))
        while (key '= "") {
            set itemInternalName = productionName _ "||Settings-" _ $listget(key,1) _ "|" _ $listget(key,2) _ ".PTD"
            set modifiedItems(itemInternalName) = "D"
            set key = $order(^mtempsscProd($job,"items",key))
        }
        // If editing from SMP, get the modified items from a cache stored in OnBeforeSave.
        // Only do this if there are no added/deleted items, because otherwise production settings will be incorrectly included.
        if '$data(modifiedItems) {
            merge modifiedItems = ^mtempsscProd($job,"modifiedItems")
        }
    } else {
        // If editing/adding/deleting from Studio, get the modified items from a percent variable set in OnBeforeSave.
        // FUTURE: implement this to support Studio.
    }
}

/// Check if current CSP session is EnsPortal page
ClassMethod IsEnsPortal() As %Boolean
{
	If $IsObject($Get(%session)) && ($Get(%request.Data("pageclass","1")) [ "EnsPortal") {
		Return 1
	}
	Return 0
}

/// Perform check if Production Decomposition logic should be used for given item
ClassMethod IsProductionClass(className As %String, nameMethod As %String) As %Boolean
{
	if (className '= "") && $$$comClassDefined(className) {
		return $classmethod(className, "%Extends", "Ens.Production")
	} else {
		set filename = $classmethod($$SrcCtrlCls^%buildccr, nameMethod, className_".CLS")
		if ##class(%File).Exists(filename) {
			$$$ThrowOnError($System.OBJ.Load(filename))
		}
		set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className)
		if $isobject(classDef) && ##class(%Dictionary.ClassDefinition).%ExistsId(classDef.Super) {
			return $classmethod(classDef.Super, "%Extends", "Ens.Production")
		}
	}
	return 0
}

/// Given a file name for a PTD item, returns a suggested internal name.
ClassMethod ParseExternalName(externalName, Output internalName)
{
    set file = $piece(externalName, "/", *)
    set deployDoc = ##class(EnsLib.EDI.XML.Document).%New(externalName)
    set exportNotesPTDText = $ZCVT(deployDoc.GetValueAt("/Export/Document[1]/1"),"I","XML")
    set exportNotesPTD = ##class(EnsLib.EDI.XML.Document).%New(exportNotesPTDText)
    set productionName = exportNotesPTD.GetValueAt("/Deployment/Creation/SourceProduction")
    if $extract(file,1,9) = "ProdStgs-" {
        set internalName = productionName_"||ProductionSettings-"_productionName_".PTD"
    } else {
        // Special case for Config Item Settings PTD, requires checking PTD CDATA for Item and Class name
        set settingsPTDText = $zconvert(deployDoc.GetValueAt("/Export/Document[2]/1"),"I","XML")
        set settingsPTD = ##class(EnsLib.EDI.XML.Document).%New(settingsPTDText)
        set itemClass = settingsPTD.GetValueAt("/Item/@ClassName")
        set itemName = settingsPTD.GetValueAt("/Item/@Name")
        set internalName = productionName_"||Settings-"_itemName_"|"_itemClass_".PTD"
    }
}

/// Given an internal name for a PTD item, returns a suggested filename for export, as well as:
/// - itemName: name of the configuration item
/// - productionName: name of the associated production
/// - isProdSettings: if true, this item is a production settings; if false, this item is a configuration item settings
ClassMethod ParseInternalName(internalName, noFolders As %Boolean = 0, Output fileName, Output itemName, Output productionName, Output isProdSettings As %Boolean)
{
    set name = $piece(internalName,".",1,*-1)
    if 'noFolders {
        set name = $replace(name,"||","/")
        set $ListBuild(productionName, name) = $ListFromString(name, "/")
    }
    // Abbreviate "ProductionSettings" to "ProdStgs", "Settings" to "Stgs".
    Set prefix = $Case($Extract(name), "P":"ProdStgs-", "S":"Stgs-", :"")
    set isProdSettings = ($Extract(name) = "P")
    Set name = $Piece(name,"-",2,*)
    set $ListBuild(itemName, itemClassName) = $ListFromString(name, "|")
    set name = prefix_$select(
        $get(itemClassName) '= "": itemName_$zhex($zcrc(itemClassName,6)),
        1: name
    )
    if 'noFolders {
        set name = productionName _ "/" _ name
    }
    set fileName = $translate($replace(name, ".", "_") _ ".xml", "\", "/")
}

/// Given an internal name for a PTD item, removes that item from the production.
ClassMethod RemoveItem(internalName, noFolders As %Boolean = 0) As %Status
{
    set sc = $$$OK
    try {
        if '##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
            quit
        }
        do ..ParseInternalName(internalName, noFolders, , .itemName, .productionName, .isProdSettings)
        if 'isProdSettings {
            set production = ##class(Ens.Config.Production).%OpenId(productionName,,.sc)
            quit:$$$ISERR(sc)
            set configItem = production.OpenItemByConfigName(itemName,.sc)
            quit:$$$ISERR(sc)
            do production.RemoveItem(configItem)
            set sc = production.%Save()
            quit:$$$ISERR(sc)
        }
    } catch err {
        set sc = err.AsStatus()
    }
    return sc
}

/// Given internal name for a Production Settings PTD, creates the corresponding Production 
/// Class if it does not already exist in this namespace
ClassMethod CreateProduction(productionName As %String, superClasses = "") As %Status
{
	set classDef = ##class(%Dictionary.ClassDefinition).%New(productionName)
	if superClasses '= "" {
		set classDef.Super = superClasses
	} else {
		set classDef.Super = "Ens.Production"
	}
	set productionXData = ##class(%Dictionary.XDataDefinition).%New()
	set productionXData.Name = "ProductionDefinition"
	set sc = productionXData.Data.WriteLine("<Production Name="""_productionName_"""/>")
	if $$$ISERR(sc) return sc
	set sc = classDef.XDatas.Insert(productionXData)
	if $$$ISERR(sc) return sc
	set sc = classDef.%Save()
	if $$$ISERR(sc) return sc
	set sc = $System.OBJ.Compile(productionName)
	return sc
}

}
