Include SourceControl.Git

/// Contains utilities for production decomposition that are specific to git-source-control
Class SourceControl.Git.Util.Production
{

/// Baselines all productions in this namespace from single-file to decomposed or vice versa.
ClassMethod BaselineProductions()
{
    set st = $$$OK
    set settings = ##class(SourceControl.Git.Settings).%New()
    set rs = ##class(%Dictionary.ClassDefinition).SubclassOfFunc("Ens.Production")
    throw:rs.%SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(rs.%SQLCODE,rs.%Message)
    while rs.%Next(.sc) {
        $$$ThrowOnError(sc)
        set productionName = rs.Name
        set productionInternalName = productionName _ ".cls"
        if '##class(SourceControl.Git.Utils).FileIsMapped(productionInternalName) {
            if settings.decomposeProductions {
                write !, "Decomposing production: " _ productionInternalName
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
                write !, "Recomposing production: " _ productionInternalName
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

}
