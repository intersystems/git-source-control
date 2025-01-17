Include SourceControl.Git

/// Contains utilities for production decomposition that are specific to git-source-control
Class SourceControl.Git.Util.Production
{

ClassMethod BaselineProduction(productionName, settings As SourceControl.Git.Settings = {##class(SourceControl.Git.Settings).%New()})
{
    set productionInternalName = productionName _ ".cls"
    if '##class(SourceControl.Git.Utils).FileIsMapped(productionInternalName) {
        if settings.decomposeProductions {
            write !, "Exporting production in decomposed format: " _ productionInternalName
            if ##class(SourceControl.Git.Utils).IsInSourceControl(productionInternalName) {
                set st = ##class(SourceControl.Git.Utils).RemoveFromSourceControl(productionInternalName)
                $$$ThrowOnError(st)
            }
            set st = ##class(SourceControl.Git.Production).ExportProductionDefinitionShards(productionName,"FullExternalName",.itemInternalNames)
            $$$ThrowOnError(st)
            set key = $order(itemInternalNames(""))
            while (key '= "") {
                set st = ##class(SourceControl.Git.Utils).AddToSourceControl(key)
                $$$ThrowOnError(st)
                set key = $order(itemInternalNames(key))
            }
        } else {
            write !, "Exporting production in class format: " _ productionInternalName
            set st = ##class(SourceControl.Git.Utils).AddToSourceControl(productionInternalName)
            $$$ThrowOnError(st)
            set key = $order(@##class(SourceControl.Git.Utils).#Storage@("items", ""))
            while (key '= "") {
                if $match(key,"^"_productionName_"\|\|.*\.(?i)ptd$") {
                    set st = ##class(SourceControl.Git.Utils).RemoveFromSourceControl(key)
                    $$$ThrowOnError(st)
                }
                set key = $order(@##class(SourceControl.Git.Utils).#Storage@("items", key))
            }
        }
    }
}

/// Baselines all productions in this namespace from single-file to decomposed or vice versa.
ClassMethod BaselineProductions()
{
    set st = $$$OK
    set settings = ##class(SourceControl.Git.Settings).%New()
    set rs = ##class(%Dictionary.ClassDefinition).SubclassOfFunc("Ens.Production")
    throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
    while rs.%Next(.sc) {
        $$$ThrowOnError(sc)
        do ..BaselineProduction(rs.Name, settings)
    }
}

/// Determines whether an item has type PTD based on the external name, not reliant on the file existing
ClassMethod ItemIsPTD(externalName) As %Boolean
{
    if $zconvert($piece(externalName,".",*),"l") '= "xml" {
        return 0
    }
    set settings = ##class(SourceControl.Git.Settings).%New()
    set normFilePath = $replace(externalName,"\","/")
    set key = $order($$$SourceMapping("PTD",""))
    while (key '= "") {
        set directory = $replace($$$SourceMapping("PTD",key), "\","/")
        if $find(normFilePath, directory) = ($length(directory) + 1) {
            return 1
        }
        set key = $order($$$SourceMapping("PTD",key))
    }
    return 0
}

/// Given the path to a directory that contains production items, this method will import them all
/// and delete any custom items from the production configuration that do not exist in the directory.
/// This method may be called on a namespace that is not configured with Embedded Git for source control.
ClassMethod LoadProductionsFromDirectory(pDirectoryName, Output pFailedItems) As %Status
{
    set st = $$$OK
    try {
        set rs = ##class(%File).FileSetFunc(pDirectoryName,,,1)
        throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
        kill itemsOnDisk
        while rs.%Next() {
            continue:rs.Type'="D"
            set rs2 = ##class(%File).FileSetFunc(rs.Name,"*.xml",,0)
            throw:rs2.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs2.%SQLCODE,rs2.%Message)
            while rs2.%Next() {
                set filePath = rs2.Name
                $$$ThrowOnError(##class(SourceControl.Git.Production).ParseExternalName(filePath,.internalName))
                set itemName = "", itemClassName = "", productionName = ""
                do ##class(SourceControl.Git.Production).ParseInternalName(internalName,,,.itemName,.itemClassName,.productionName)
                quit:productionName=""
                if (itemName'="") && (itemClassName'="") {
                    set itemsOnDisk(productionName, itemName, itemClassName) = 1
                }
                // if production does not exist, create it
                if '$isobject(##class(Ens.Config.Production).%OpenId(productionName)) {
                    $$$ThrowOnError(##class(SourceControl.Git.Production).CreateProduction(productionName))
                }
                set st = ##class(SourceControl.Git.Production).ImportPTD(filePath, productionName)
                if $$$ISERR(st) {
                    set pFailedItems(filePath) = st
                }
            }
        }
        // handle deletes by iterating through XDATA of each production class. for every config item that is not in itemsOnDisk, delete it.
        set key = $order(itemsOnDisk(""))
        while (key '= "") {
            set classDef = ##class(%Dictionary.ClassDefinition).%OpenId(key)
            if $isobject(classDef) {
                set productionXData = $$$NULLOREF
                for i=1:1:classDef.XDatas.Count() {
                    set xdata = classDef.XDatas.GetAt(i)
                    if xdata.Name = "ProductionDefinition" {
                        set productionXData = xdata
                        quit
                    }
                }
                if $isobject(productionXData) {
                    $$$ThrowOnError(##class(%XML.XPATH.Document).CreateFromStream(productionXData.Data,.xdoc))
                    $$$ThrowOnError(xdoc.EvaluateExpression("/Production","Item/@Name | Item/@ClassName",.results))
                    for i=1:2:results.Count() {
                        set itemName = results.GetAt(i).Value
                        set itemClassName = results.GetAt(i+1).Value
                        if (itemName'="") && (itemClassName'="") && '$get(itemsOnDisk(key,itemName, itemClassName)) {
                            write !, "Removing item from production ", key, ": ", itemName, ":", itemClassName
                            set internalName = ##class(SourceControl.Git.Production).CreateInternalName(key,itemName, itemClassName)
                            set st = ##class(SourceControl.Git.Production).RemoveItem(internalName)
                            if $$$ISERR(st) {
                                set pFailedItems(itemName, itemClassName) = st
                            }
                        }
                    }
                }
            }
            set key = $order(itemsOnDisk(key))
        }
    } catch err {
        set st = err.AsStatus()
    }
    if $data(pFailedItems) set st = $$$ADDSC($$$ERROR($$$GeneralError,"Some items failed to deploy."),st)
    return st
}

}
