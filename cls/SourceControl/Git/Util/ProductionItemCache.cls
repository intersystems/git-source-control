/// Maintains a cache mapping PTD items' full external names to internal names. 
/// This is only required to deploy deletes because once the file is deleted from disk, there is 
/// no way to determine the internal name for it.
Class SourceControl.Git.Util.ProductionItemCache
{

ClassMethod Store(externalName, internalName)
{
    if externalName '= "" {
        set @##class(SourceControl.Git.Utils).#Storage@("ptd_items", $translate(externalName,"\","/")) = internalName
    }
}

ClassMethod Lookup(externalName)
{
    return $select(
        externalName="":"",
        1:$get(@##class(SourceControl.Git.Utils).#Storage@("ptd_items", $translate(externalName,"\","/"))))
}

ClassMethod Clear()
{
    kill @##class(SourceControl.Git.Utils).#Storage@("ptd_items")
}

}
