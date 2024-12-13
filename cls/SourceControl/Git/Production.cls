/// This is a replica of %Studio.SourceControl.Production for backwards compatibility with older IRIS versions.
Class SourceControl.Git.Production Extends %RegisteredObject
{

/// Exports settings for a given Production and each Config Item from
/// the ProductionDefinition as separate XMLs. These are exported to 
/// the appropriate file based on nameMethod of the source control class
ClassMethod ExportProductionDefinitionShards(productionClass As %String, nameMethod As %String, Output internalNames) As %Status
{
    Set sc = ..ExportProductionSettings(productionClass, nameMethod, .internalName)
    If $$$ISERR(sc) {
	    Return sc
    }
    Set internalNames(internalName) = 1

    // next, export each item to a separate file
    Set rs = ..ExecDirectNoPriv(
        "select Name, ClassName from Ens_Config.Item where Production = ?"
        , productionClass
    )
    Throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
    While rs.%Next() {
        Set ptdName = ""
        Set item = ##class(Ens.Config.Production).OpenItemByConfigName(productionClass _ "||" _ rs.Name _ "|" _ rs.ClassName)
        If $isobject(item) { 
            Set sc = ..ExportConfigItemSettings(productionClass, item, nameMethod, .internalName)
            If $$$ISERR(sc) {
	            Return sc
            }
            Set internalNames(internalName) = 1
        }
    }
    Return $$$OK
}

/// Removes settings for a given Production and each Config Item from
/// source control. This marks each of them for delete and is triggered
/// by deleting a decomposed Production.
ClassMethod DeleteProductionDefinitionShards(productionClass As %String, deleteMethod As %String, nameMethod As %String) As %Status
{
	set sc = $$$OK
	if '$isobject($get(%SourceControl)) {
		new %SourceControl
		$$$ThrowOnError(##class(%Studio.SourceControl.Interface).SourceControlCreate())
	}
	set settingsPTD = ..CreateInternalName(productionClass,,,1)
	set sourceControlClass = ##class(%Studio.SourceControl.Interface).SourceControlClassGet()
	set settingsPTDFile = $classmethod(sourceControlClass, nameMethod, settingsPTD)
	// if the Production settings PTD exists, delete all PTDs for this Production
	if ##class(%File).Exists(settingsPTDFile) {
		set ptdDir = ##class(%File).GetDirectory(settingsPTDFile)
        set statement = ##class(%SQL.Statement).%New()
        try {
            // execute without priv checking if possible on this IRIS version
            set sc = statement.%PrepareClassQuery("%File","FileSet",0)
        } catch err {
            set sc = statement.%PrepareClassQuery("%File","FileSet")
        }
        quit:$$$ISERR(sc)
		set rs = statement.%Execute(ptdDir, "*.xml")
        throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
		while rs.%Next(.sc) {
			quit:$$$ISERR(sc)
			set ptdFilename = rs.Data("Name")
			set sc = ##class(SourceControl.Git.Production).ParseExternalName(ptdFilename, .ptdInternalName)
			quit:$$$ISERR(sc)
			// TODO: Consider reverting delete if any ptd is not editable by current user
			set sc = $method(%SourceControl, deleteMethod, ptdInternalName)
			quit:$$$ISERR(sc)
		}
	}
	return sc
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
        // remove the LastModified timestamp from the exported file
        set fileStream = ##class(%Stream.FileCharacter).%OpenId(exportPath,,.st)
        $$$ThrowOnError(st)
        set fileCopy = ##class(%Stream.TmpCharacter).%New()
        set timestampFound = 0
        while 'fileStream.AtEnd {
            set line = fileStream.ReadLine()
            set regex = ##class(%Regex.Matcher).%New("\<Project name="".*"" LastModified=""(.*)""\>")
            if 'timestampFound && regex.Match(line) {
                set timestampFound = 1
                set timestamp = regex.Group(1)
                set line = $replace(line, timestamp, "1841-01-01 00:00:00.0000000")
            }
            do fileCopy.WriteLine(line)
        }
        $$$ThrowOnError(fileStream.CopyFromAndSave(fileCopy))
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
    Set sc = $$$OK
    If $Piece($Piece(name,"||",2),"|",2) = "" {
        Set sc = ..ExportProductionSettings(productionName, nameMethod)
    } Else {
        Set configItemName = productionName_"||"_$Piece(itemName, "Settings-", 2)_"|"_itemClassName
        Set item = ##class(Ens.Config.Production).OpenItemByConfigName(configItemName)
        If $IsObject(item) {
            Set sc = ..ExportConfigItemSettings(productionName, item, nameMethod)
        }
    }
    Return sc
}

/// Imports a PTD into a produciton given an external name and produciton name
ClassMethod ImportPTD(externalName As %String, productionName As %String) As %Status
{
	try {
		set ^IRIS.Temp("sscProd",$job,"bypassLock") = 1
		set rollbackFile = ##class(%File).TempFilename()
		set sc = ##class(Ens.Deployment.Deploy).DeployCode(externalName,productionName,0,rollbackFile)
		do ##class(%File).Delete(rollbackFile)
		kill ^IRIS.Temp("sscProd",$job,"bypassLock")
	} catch err {
		kill ^IRIS.Temp("sscProd",$job,"bypassLock")
		set sc = err.AsStatus()
	}
	return sc
}

/// Imports all PTDs within a given directory. Also recursively imports from all subdirectories
ClassMethod ImportPTDsDir(directory As %String, isDecompMethod As %String = "") As %Status
{
	set sc = $$$OK
	set rs = ##class(%ResultSet).%New("%File:FileSet")
	$$$ThrowOnError(rs.Execute(directory, "*.xml", "", 1))
	throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE, rs.%Message)
	while rs.Next() {
		set path = rs.Data("Name")
		set type = rs.Data("Type")
		if type = "D" {
			set sc = ..ImportPTDsDir(path)
		} else {
			$$$ThrowOnError(..ParseExternalName(path, .internalName, .prodName))
			set srcCtrlCls = ##class(%Studio.SourceControl.Interface).SourceControlClassGet()
			set isDecomp = $select(isDecompMethod="":1, 1:$classMethod(srcCtrlCls, isDecompMethod, internalName))
			if isDecomp {
				set filename = ##class(%File).GetFilename(path)
				if ($extract(filename) = "P") && '$$$comClassDefined(prodName) {
					$$$ThrowOnError(..CreateProduction(prodName))
				}
				set sc = ..ImportPTD(path, prodName)
			}
		}
	}
	return sc
}

/// Export a single Production Config Item. For a given Ens.Config.Item, the 
/// exports the PTD for this item to the file system under the directory specified
ClassMethod ExportConfigItemSettings(productionClass As %String, item As %RegisteredObject, nameMethod As %String, Output internalName As %String) As %Status
{
    set internalName = ..CreateInternalName(productionClass, item.Name, item.ClassName, 0)
	Set externalName = $ClassMethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(), nameMethod, internalName)
	Set filename = ##class(%File).NormalizeFilename(externalName)
    set st = ##class(Ens.Deployment.Utils).CreatePTDFromItem(.item, .ptdName)
    $$$QuitOnError(st)
    set st = ..ExportProjectForPTD(productionClass, ptdName, filename)
    $$$QuitOnError(st)
    Return st
}

/// Exports the Production settings from ProductionDefinition given the Production
/// class name
ClassMethod ExportProductionSettings(productionClass As %String, nameMethod As %String, Output internalName As %String) As %Status
{
    set internalName = ..CreateInternalName(productionClass,,,1)
    Set class = ##class(%Dictionary.CompiledClass).%OpenId(productionClass)
    Set sc = ##class(Ens.Deployment.Utils).CreatePTDFromProduction(class, .ptdName)
    If $$$ISERR(sc) {
	    Return sc
    }
    Set externalName = $ClassMethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(), nameMethod, internalName)
    Set filename = ##class(%File).NormalizeFilename(externalName)
    set sc = ..ExportProjectForPTD(productionClass, ptdName, filename)
    Return sc
}

ClassMethod GetModifiedItemsBeforeSave(internalName, Location, Output modifiedItems)
{
    kill modifiedItems
    set productionName = $piece(internalName,".",1,*-1)
    set productionConfig = ##class(Ens.Config.Production).%OpenId(productionName)
    if ..IsEnsPortal() {
        // If editing from SMP, get the modified items by looking at %IsModified on the items in the production in memory.
        // No way to know if an item has been added or deleted, so ignore it.
        if $isobject(productionConfig) {
            set modifiedItem = $$$NULLOREF
            for i=1:1:productionConfig.Items.Count() {
                set item = productionConfig.Items.GetAt(i)
                if item.%IsModified() {
                    set modifiedItem = item
                    quit
                }
                for j=1:1:item.Settings.Count() {
                    set setting = item.Settings.GetAt(j)
                    if $isobject(setting) && setting.%IsModified() {
                        set modifiedItem = item
                        quit
                    }
                }
            }
            set modifiedInternalName = ""
            if $isobject(modifiedItem) {
                set modifiedInternalName = ..CreateInternalName(productionName, modifiedItem.Name, modifiedItem.ClassName, 0)
            } else {
                // cannot check %IsModified on production config settings because they are not actually modified at this point.
                // workaround: just assume any change not to a specific item is to the production settings
                set modifiedInternalName = ..CreateInternalName(productionName,,,1)
            }
        }
        if ($get(modifiedInternalName) '= "") {
            set modifiedItems(modifiedInternalName) = "M"
        }
    } else {
        // FUTURE: get the actually modified items by comparing the XDATA in Location with the XDATA in the compiled class
        // If making changes from Studio, list every item in the production.
        if $isobject(productionConfig) {
            set modifiedItems(..CreateInternalName(productionName,,,1)) = "M"
            for i=1:1:productionConfig.Items.Count() {
                set item = productionConfig.Items.GetAt(i)
                set modifiedItems(..CreateInternalName(productionName, item.Name, item.ClassName, 0)) = "M"
            }
        }
    }
    // populate data for use in OnAfterSave
    kill ^IRIS.Temp("sscProd",$job,"modifiedItems")
    merge ^IRIS.Temp("sscProd",$job,"modifiedItems") = modifiedItems
    // FUTURE: use a percent variable or PPG instead
    kill ^IRIS.Temp("sscProd",$job,"items")
    set rs = ..ExecDirectNoPriv(
        "select Name, ClassName from Ens_Config.Item where Production = ?"
        , productionName)
    throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
    while rs.%Next() {
        set ^IRIS.Temp("sscProd",$job,"items",$listbuild(rs.Name, rs.ClassName)) = 1
    }
}

ClassMethod GetModifiedItemsAfterSave(internalName, Output modifiedItems)
{
    kill modifiedItems
    set productionName = $piece(internalName,".",1,*-1)
    if ..IsEnsPortal() {
        // If adding/deleting from SMP, get the modified items by comparing items in temp global with items now
        set rs = ..ExecDirectNoPriv(
            "select Name, ClassName from Ens_Config.Item where Production = ?"
            , productionName)
        throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
        while rs.%Next() {
            if '$get(^IRIS.Temp("sscProd",$job,"items", $listbuild(rs.Name, rs.ClassName))) {
                set itemInternalName = ..CreateInternalName(productionName, rs.Name, rs.ClassName, 0)
                set modifiedItems(itemInternalName) = "A"
            }
            kill ^IRIS.Temp("sscProd",$job,"items", $listbuild(rs.Name, rs.ClassName))
        }
        set key = $order(^IRIS.Temp("sscProd",$job,"items",""))
        while (key '= "") {
            set itemInternalName = ..CreateInternalName(productionName, $listget(key,1), $listget(key,2), 0)
            set modifiedItems(itemInternalName) = "D"
            set key = $order(^IRIS.Temp("sscProd",$job,"items",key))
        }
        // If editing from SMP, get the modified items from a cache stored in OnBeforeSave.
        // Only do this if there are no added/deleted items, because otherwise production settings will be incorrectly included.
        if '$data(modifiedItems) {
            merge modifiedItems = ^IRIS.Temp("sscProd",$job,"modifiedItems")
        }
    } else {
        // If editing in the IDE, list every item in the production.
        // FUTURE: get the actually modified items using the temp global set in OnBeforeSave
        set productionConfig = ##class(Ens.Config.Production).%OpenId(productionName)
        if $isobject(productionConfig) {
            set modifiedItems(..CreateInternalName(productionName,,,1)) = "M"
            for i=1:1:productionConfig.Items.Count() {
                set item = productionConfig.Items.GetAt(i)
                set modifiedItems(..CreateInternalName(productionName, item.Name, item.ClassName, 0)) = "M"
            }
        }
    }
}

/// Check if current CSP session is EnsPortal page
ClassMethod IsEnsPortal() As %Boolean
{
	Return $Data(%request) && '($IsObject(%request) && 
        ((%request.UserAgent [ "Code") || (%request.UserAgent [ "node-fetch")))
}

/// Perform check if Production Decomposition logic should be used for given item
ClassMethod IsProductionClass(className As %String, nameMethod As %String) As %Boolean
{
	if (className '= "") && $$$comClassDefined(className) {
		return $classmethod(className, "%Extends", "Ens.Production")
	} else {
		// check if there exists a Production settings PTD export for ths Production
		set settingsPTD = ..CreateInternalName(className,,,1)
		set settingsPTDFilename = $classmethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(), nameMethod, settingsPTD)
		if ##class(%File).Exists(settingsPTDFilename) {
			return 1
		}
		// check if there is a class export for this Production, load it for class definition
		set filename = $classmethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(), nameMethod, className_".CLS")
		if ##class(%File).Exists(filename) && (##class(%File).GetFileSize(filename) '= 0) {
			$$$ThrowOnError($System.OBJ.Load(filename))
		}
		// if Production exists as a class definition on the server, check if extending Ens.Production
		set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(className)
		if $isobject(classDef) {
			for i=1:1:classDef.XDatas.Count() {
				set xdata = classDef.XDatas.GetAt(i)
				if xdata.Name = "ProductionDefinition" return 1
			}
		}
	}
	return 0
}

/// Given a file name for a PTD item, returns a suggested internal name. This method assumes that the file exists on disk.
ClassMethod ParseExternalName(externalName, Output internalName = "", Output productionName = "") As %Status
{
	set sc = $$$OK
    try {
        set extNameNormalized = $replace(externalName, "\", "/")
        set file = $piece(extNameNormalized, "/", *)
        if $extract(file,1,9) = "ProdStgs-" {
            set productionName = $replace($extract(file,10,*-4), "_", ".")
            set internalName = ..CreateInternalName(productionName,,,1)
        } else {
            if ##class(%File).Exists(externalName) {
                // Special case for Config Item Settings PTD, requires checking PTD CDATA for Item and Class name
                set deployDoc = ##class(EnsLib.EDI.XML.Document).%New(externalName)
                set exportNotesPTDText = $ZCVT(deployDoc.GetValueAt("/Export/Document[1]/1"),"I","XML")
                set exportNotesPTD = ##class(EnsLib.EDI.XML.Document).%New(exportNotesPTDText)
                set productionName = exportNotesPTD.GetValueAt("/Deployment/Creation/SourceProduction")
                set settingsPTDText = $zconvert(deployDoc.GetValueAt("/Export/Document[2]/1"),"I","XML")
                // unquote embedded CDATA close markers - see Ens.Util.ProjectTextDocument StreamToGbl method
                set settingsPTDText = $replace(settingsPTDText,"]*]>", "]]>")
                set settingsPTD = ##class(EnsLib.EDI.XML.Document).%New(settingsPTDText)
                set itemClass = settingsPTD.GetValueAt("/Item/@ClassName")
                set itemName = settingsPTD.GetValueAt("/Item/@Name")
                set internalName = ..CreateInternalName(productionName, itemName, itemClass, 0)
            } else {
            set sc = $$$ERROR($$$GeneralError, "Item settings PTD file " _ externalName _ " does not exist. Cannot parse external name.")
            }
        }
    } catch err {
        set sc = err.AsStatus()
    }
    return sc
}

/// Given an internal name for a PTD item, returns a suggested filename for export, as well as:
/// - itemName: name of the configuration item
/// - productionName: name of the associated production
/// - isProdSettings: if true, this item is a production settings; if false, this item is a configuration item settings
ClassMethod ParseInternalName(internalName, noFolders As %Boolean = 0, Output fileName, Output itemName, Output itemClassName, Output productionName, Output isProdSettings As %Boolean)
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

/// Calculates the internal name for a decomposed production item
ClassMethod CreateInternalName(productionName = "", itemName = "", itemClassName = "", isProductionSettings As %Boolean = 0) As %String
{
    return $select(
        isProductionSettings: productionName_"||ProductionSettings-"_productionName_".PTD",
        1: productionName _ "||Settings-" _ itemName _ "|" _ itemClassName _ ".PTD"
    )
}

/// Given an external name for a PTD item, removes that item from the production.
ClassMethod RemoveItemByExternalName(externalName, nameMethod) As %Status
{
    set sc = $$$OK
    set productionName = $replace($piece($replace(externalName,"\","/"),"/",*-1),"_",".")
    set production = ##class(Ens.Config.Production).%OpenId(productionName,,.sc)
    $$$QuitOnError(sc)
    set itemToRemove = $$$NULLOREF
    for i=1:1:production.Items.Count() {
        set configItem = production.Items.GetAt(i)
        set itemInternalName = ..CreateInternalName(productionName, configItem.Name, configItem.ClassName)
        set itemExternalName = $classmethod(##class(%Studio.SourceControl.Interface).SourceControlClassGet(), nameMethod, itemInternalName)
        if itemExternalName = externalName {
            set itemToRemove = configItem
            quit
        }
    }
    do production.RemoveItem(itemToRemove)
    return production.%Save()
}

/// Given an internal name for a PTD item, removes that item from the production.
ClassMethod RemoveItem(internalName, noFolders As %Boolean = 0) As %Status
{
    set sc = $$$OK
    try {
        if '##class(%Library.EnsembleMgr).IsEnsembleNamespace() {
            quit
        }
        do ..ParseInternalName(internalName, noFolders, , .itemName, .itemClassName, .productionName, .isProdSettings)
        if 'isProdSettings {
            set production = ##class(Ens.Config.Production).%OpenId(productionName,,.sc)
            quit:$$$ISERR(sc)
            set configItem = ##class(Ens.Config.Production).OpenItemByConfigName(productionName_"||"_itemName_"|"_itemClassName,.sc)
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

/// Given an internal name of a Production and an IRIS user, populate an array with the filenames
/// for each of their current uncommitted changes associated with the given Production
ClassMethod GetUserProductionChanges(productionName As %String, ByRef items)
{
	set sql = "SELECT InternalName, Action FROM %Studio_SourceControl.Change WHERE ChangedBy = ? AND Committed = 0 AND InternalName %STARTSWITH ?"
	set rs = ..ExecDirectNoPriv(sql,$username,productionName_"||")
    throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
	while rs.%Next() {
		set items(rs.InternalName) = rs.Action
	}
	quit $$$OK
}

/// Executes a SQL query without privilege checking if possible on this IRIS version
ClassMethod ExecDirectNoPriv(sql, args...) As %SQL.StatementResult
{
	// once minimum version is IRIS 2021.1.3, remove and just use %ExecDirectNoPriv
    try {
        set rs = ##class(%SQL.Statement).%ExecDirectNoPriv(,sql,args...)
    } catch err {
        set rs = ##class(%SQL.Statement).%ExecDirect(,sql,args...)
    }
    return rs
}

/// Returns value the Major.Minor version for this instance, so it can be used in comparison code which makes sure certain features are used in appropriate versions
ClassMethod InstanceVersion() As %Numeric [ CodeMode = expression ]
{
$P($SYSTEM.Version.GetNumber(),".",1,2)
}

}
