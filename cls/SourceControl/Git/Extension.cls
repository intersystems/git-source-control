Import SourceControl.Git

/// Main source control extension class, configured namespace-wide to enable use via VSCode and Studio
Class SourceControl.Git.Extension Extends %Studio.SourceControl.Base
{

Parameter DOMAIN = "Studio";

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="Status" />
<MenuItem Name="Settings" />
<MenuItem Name="Init" />
<MenuItem Name="GitWebUI" />
<MenuItem Separator="true"/>
<MenuItem Name="AddToSC" />
<MenuItem Name="RemoveFromSC"/>
<MenuItem Name="Revert" />
<MenuItem Name="Commit" />
<MenuItem Separator="true"/>
<MenuItem Name="Sync" />
<MenuItem Name="Push" />
<MenuItem Name="Fetch" />
<MenuItem Name="Pull" />
<MenuItem Separator="true"/>
<MenuItem Name="NewBranch" />
<MenuItem Name="SwitchBranch" />
<MenuItem Separator="true"/>
<MenuItem Name="Export" />
<MenuItem Name="ExportForce" />
<MenuItem Name="Import" />
<MenuItem Name="ImportForce" />
</Menu>
<Menu Name="%SourceContext" Type="1">
<MenuItem Name="AddToSC" />
<MenuItem Name="RemoveFromSC"/>
<MenuItem Name="Revert" />
<MenuItem Name="Commit" />
</Menu>
</MenuBase>
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
    // If namespace change event
    if Type = 1, Name = 5 {
        // reroute to Status menu option
        set Name = "%SourceMenu,Status"
    } 

    if (Type = 1) && ((Name = 1) || (Name = 7)) {
        do ..AddToSourceControl(InternalName)
    }
    

    #dim ec as %Status = $$$OK
    #dim menu as %Status = $piece(Name, ",", 1)
    if menu '= "%SourceMenu", menu'="%SourceContext" {
        quit $$$OK
    }

    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    set ec = ##class(SourceControl.Git.Utils).UserAction(InternalName, Name, .Target, .Action, .Reload, .Msg)
    quit ec
}

Method AfterUserAction(Type As %Integer, Name As %String, InternalName As %String, Answer As %Integer, Msg As %String = "", ByRef Reload As %Boolean) As %Status
{
    #dim ec as %Status = $$$OK
    #dim menu as %Status = $piece(Name, ",", 1)
    if menu '= "%SourceMenu", menu'="%SourceContext" {
        quit $$$OK
    }
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    set ec = ##class(SourceControl.Git.Utils).AfterUserAction(Type, Name, InternalName, .Answer, .Msg, .Reload)
    quit ec
}

Method LocalizeName(name As %String) As %String
{
    quit $case(name,
        "Settings":$$$Text("@Settings@Settings"),
        "Init":$$$Text("@Init@Initialize"),
        "GitWebUI":$$$Text("@GitWebUI@Launch Git UI"),
        "Export":$$$Text("@Export@Export All"),
        "ExportForce":$$$Text("@ExportForce@Export All (Force)"),
        "Import":$$$Text("@Import@Import All"),
        "ImportForce":$$$Text("@ImportForce@Import All (Force)"),
        "AddToSC":$$$Text("@AddToSC@Add"),
        "RemoveFromSC":$$$Text("@RemoveFromSC@Remove"),
        "NewBranch":$$$Text("@NewBranch@Create a new branch"),
        "SwitchBranch":$$$Text("@SwitchBranch@Check out an existing branch"),
        "Revert":$$$Text("@Revert@Discard changes to file"),
        "Commit":$$$Text("@Commit@Commit changes to file"),
        "Sync":$$$Text("@Sync@Sync"),
        "Push":$$$Text("@Push@Push to remote branch"),
        "Fetch":$$$Text("@Fetch@Fetch from remote"),
        "Pull":$$$Text("@Pull@Pull changes from remote branch"),
        "Status": $$$Text("@Status@Status"),
        :name)
}

Method OnSourceMenuItem(name As %String, ByRef Enabled As %String, ByRef DisplayName As %String, InternalName As %String) As %Status
{
    if name = "Settings" {
        set Enabled = 1
        quit $$$OK
    }
    if ##class(SourceControl.Git.Utils).NeedSettings() {
        set Enabled = -1
        quit $$$OK
    }
    if ##class(SourceControl.Git.Utils).IsNamespaceInGit() {

        if $listfind($listbuild("AddToSC", "RemoveFromSC", "Revert", "Commit"), name) {
            quit ..OnSourceMenuContextItem(InternalName,name,.Enabled,.DisplayName)
        }

        if ##class(SourceControl.Git.Utils).BasicMode() {
            set Enabled = $CASE(name,
                "Status": 1,
                "GitWebUI" : 1,
                "NewBranch": 1,
                "Sync": 1,
                "": 1,
                :-1
            
            )
        } else {
            set Enabled = $CASE(name, 
                // cases
                "Status": 1,
                "GitWebUI" : 1,
                "Export": 1,
                "ExportForce": 1,
                "Import": 1,
                "ImportForce": 1,
                "NewBranch": 1,
                "SwitchBranch": 1,
                "Push": 1,
                "Fetch": 1,
                "Pull": 1,
                "Sync": -1,
                "": 1,
                :-1 // default
            )
        }
        
            
    } elseif ##class(SourceControl.Git.Utils).GitBinExists() {
        if name = "Init" {
        } else {
            set Enabled = -1
        }
    } else {
        set Enabled = -1
    }

    if (name = "Status") {
        set DisplayName = ..LocalizeName(name)_" (branch: "_##class(SourceControl.Git.Utils).GetCurrentBranch()_")"
    } if (name '= "") {
	    set DisplayName = ..LocalizeName(name)
    }
    quit $$$OK
}

Method OnSourceMenuContextItem(itemName As %String, menuItemName As %String, ByRef Enabled As %String, ByRef DisplayName As %String) As %Status
{
    if (itemName = "") || '##class(SourceControl.Git.Utils).IsNamespaceInGit() {
        set Enabled = -1
    } elseif (($find(itemName,",") > 0) || (##class(SourceControl.Git.Utils).Type(itemName) = "pkg")) { 
        //if more than one item is selected, we can only add/remove, no diff or blame
        // if a package is selected we should show options to add missing items and remove exisiting ones
        set Enabled = $case(menuItemName,"AddToSC":1,"RemoveFromSC":1,:-1)
    } elseif menuItemName = "Revert" {
        set Enabled = 1
        do ..GetStatus(.itemName, .isInSourceControl, .isEditable,.isCheckedOut,.userCheckedOut)
        if '(##class(SourceControl.Git.Change).IsUncommitted(##class(SourceControl.Git.Utils).FullExternalName(itemName))) || ($username '= userCheckedOut) {
            set Enabled = 0
        }
    } elseif menuItemName = "Commit" {
        set Enabled = 1
        do ..GetStatus(.itemName, .isInSourceControl, .isEditable,.isCheckedOut,.userCheckedOut)
        if '(##class(SourceControl.Git.Change).IsUncommitted(##class(SourceControl.Git.Utils).FullExternalName(itemName))) || ($username '= userCheckedOut) {
            set Enabled = 0
        }
    } elseif ##class(SourceControl.Git.Utils).IsInSourceControl(itemName) {
        set Enabled = $case(menuItemName, "AddToSC":-1,:1)
    } else {
        if (##class(SourceControl.Git.Utils).Type(itemName) = "cls") && ('$$$defClassDefined($extract(itemName, 1, $length(itemName) - 4))) {
            set Enabled = -1
        } else {
            set Enabled = $case(menuItemName, "AddToSC":1,:-1)
        }

    }
    if (menuItemName '= "") {
	    set DisplayName = ..LocalizeName(menuItemName)
    }
    quit $$$OK
}

/// This is called for every menu item returned to Studio to allow the menu to be enabled/disabled without
/// having to write a custom query for <query>MenuItems</query>. The <var>DisplayName</var> of this menu is
/// also passed by reference and this may be modified to change the appearance of this menu item. The <var>MenuName</var>
/// is the main menu name then the submenu name separated by a ','. If <var>Enabled</var> is set to -1 then it will remove
/// this menu item from the list totally, 0 will gray the menu item out and the default 1 will display the menu item as normal.
Method OnMenuItem(MenuName As %String, InternalName As %String, SelectedText As %String, ByRef Enabled As %Boolean, ByRef DisplayName As %String) As %Status
{
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)

    #dim menu as %String= $piece(MenuName,",")
    #dim name as %String = $piece(MenuName,",",2)
    if menu = "%SourceContext", name = "" {
        set DisplayName = "Git"
    }
    if menu = "%SourceMenu", name = "" {
        set DisplayName = "Git"
    }
    #dim ec as %Status = $$$OK

    if menu = "%SourceMenu" {
        set ec = ..OnSourceMenuItem(name, .Enabled, .DisplayName, InternalName)
    } elseif menu = "%SourceContext" {
        set ec = ..OnSourceMenuContextItem(InternalName, name, .Enabled, .DisplayName)
    }
    quit ec
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String, verbose As %Boolean) As %Status
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    if ##class(SourceControl.Git.Utils).IsInSourceControl(InternalName) {
        quit ##class(SourceControl.Git.Utils).ImportItem(InternalName,,0)
    }
    quit $$$OK
}

/// Called before Studio checks for the timestamp of an item.
Method OnBeforeTimestamp(InternalName As %String)
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    if $IsObject($Get(%request)) {
        set clientServerHash = ##class(%Atelier.REST).GetClientServerHash()
        if (clientServerHash '= "") {
            // suppress load / timestamp update if file on server was modified an extremely short time ago
            set file = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
            if (file '= "" && ##class(%File).Exists(file)) {
                set lastModifiedTime = ##class(%Library.File).GetFileDateModified(file)
                set diff = $System.SQL.Functions.DATEDIFF("ms",lastModifiedTime,$h)
                if (diff < 1000) {
                    quit
                }
            }
        }
    }
    quit ..OnBeforeLoad(InternalName,0)
}

/// This is called after the item has been saved to the database.
/// It may be passed a reference to the object representing the item
/// just saved. It can be use to export this documement to an external form for example.
/// Also, lock the file after export IF there are any changes to it
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
    set sc = $$$OK
    try {
        set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(.InternalName)
        set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
        if ##class(SourceControl.Git.Utils).IsNamespaceInGit() && ..IsInSourceControl(InternalName) {
            // If this is a production class and production decomposition is enabled, call recursively on all modified production items.
            if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(InternalName) {
                do ##class(%Studio.SourceControl.Production).GetModifiedItemsAfterSave(InternalName, .productionItems)
                set key = $order(productionItems(""))
                while (key '= "") {
                    if productionItems(key) = "D" {
                        set itemFilename = ..ExternalName(key)
                        if ##class(SourceControl.Git.Utils).IsInSourceControl(InternalName) && ##class(%File).Exists(itemFilename) {
                            $$$ThrowOnError(##class(SourceControl.Git.Change).AddDeletedToUncommitted(itemFilename, InternalName))
                            $$$ThrowOnError(##class(SourceControl.Git.Utils).DeleteExternalFile(InternalName))
                        }
                    } elseif '..IsInSourceControl(key) {
                        $$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl(key))
                    } else {
                        $$$ThrowOnError(..OnAfterSave(key))
                    }
                    set key = $order(productionItems(key))
                }
            }
            set filename = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
            $$$ThrowOnError(##class(SourceControl.Git.Utils).RemoveRoutineTSH(InternalName))
            $$$ThrowOnError(##class(SourceControl.Git.Utils).ExportItem(InternalName))
            if '##class(SourceControl.Git.Change).IsUncommitted(filename) {
                $$$ThrowOnError(##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", InternalName, $username, "", 1, "", "", 0))
            }
        }
    } catch e {
        do e.Log()
        set sc = e.AsStatus()
    }
    quit sc
}

/// Called after the compile of the item is done.
Method OnAfterCompile(InternalName As %String) As %Status
{
    quit ..OnAfterSave(InternalName)
}

/// Returns true if this item is in source control and false otherwise.
Method IsInSourceControl(InternalName As %String) As %Boolean [ CodeMode = expression ]
{
InternalName'="" && ##class(SourceControl.Git.Utils).IsInSourceControl(##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName))
}

/// Called before an item is deleted.
Method OnBeforeDelete(InternalName As %String) As %Status
{
    if ..IsReadOnly(InternalName) {
        // throw error if deleting readonly item
        Throw ##class(%Exception.General).%New("Can't delete in locked environment")
    } else {
        set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
        set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
        set Filename = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
        if ##class(SourceControl.Git.Utils).IsInSourceControl(InternalName) && ##class(%File).Exists(Filename) {
            quit ##class(SourceControl.Git.Change).AddDeletedToUncommitted(Filename, InternalName)
        }
        quit $$$OK
    }
}

/// Called after an item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    if ##class(SourceControl.Git.Utils).IsInSourceControl(InternalName) {
        quit ##class(SourceControl.Git.Utils).DeleteExternalFile(InternalName)
    }
    quit $$$OK
}

/// Convert the internal name, e.g. TEST.MAC, to an external name that is used to export
/// the routine/class/csp item. This is often a filename to write the file out to.
Method ExternalName(InternalName As %String) As %String
{
    quit ##class(SourceControl.Git.Utils).ExternalName(InternalName)
}

ClassMethod FullExternalName(InternalName As %String) As %String
{
    quit ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
}

Method IsReadOnly(InternalName As %String) As %Boolean
{
    quit ##class(SourceControl.Git.Utils).Locked()
}

/// Check the status of the given item
/// User should be able to edit the item if it is not locked by another user
/// Check if another user has committed any changes to the item and return the status
Method GetStatus(ByRef InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(.InternalName)
    set Editable='..IsReadOnly(),IsCheckedOut=1,UserCheckedOut=""
    if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(InternalName) {
        do ##class(%Studio.SourceControl.Production).GetModifiedItemsBeforeSave(InternalName,,.productionItems)
        //TODO: if any modified items in this production class are edited by a different user, prohibit editing
    }
    set filename=##class(SourceControl.Git.Utils).FullExternalName(.InternalName)
    set IsInSourceControl=(filename'=""&&($$$FileExists(filename)))
    if filename="" quit $$$OK
    if InternalName="" quit $$$OK
    #; If the file does not exist then it must be a new item so it is editable.
    if '$$$FileExists(filename) {
        set IsCheckedOut=0
    }
    // %MenuName and %InternalName set up by %Studio.SourceControl.Interface:MenuItems class query
    if $Data(%MenuName)#2 && $Data(%InternalName)#2 {
        if $Data(%MenuName(%InternalName)) {
            merge files = %MenuName(%InternalName)
        } else {
            do ##class(SourceControl.Git.Change).RefreshUncommitted(,,.files)
            // Cache to optimize rendering menu with multiple items dependent on status
            merge %MenuName(%InternalName) = files
        }
    } else {
        do ##class(SourceControl.Git.Change).RefreshUncommitted(,,.files)
    }
    if $get(files(InternalName)) '= "" {
        ///it's in source control, checked out, and should be locked to editing by other users
        ///find out who has it edited
        set IsCheckedOut=1
        set sc=##class(SourceControl.Git.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
        if $$$ISOK(sc) {
            if ($data(tAction)&&(UncommittedUser'=$username)){
                set msg="NOTICE: "_InternalName_" is currently checked out by user '"_UncommittedUser_"', and was last updated at "_UncommittedLastUpdated
                write !,msg
                set Editable=0
                set IsInSourceControl=0		//set this to 0 to prevent user from being prompted to Check Out file
            }
            set UserCheckedOut=UncommittedUser
        }
    } else {
        // If it doesn't show up in git status, there are no uncommitted changes so it should not be locked or checked out by any user
        set Editable=1, IsCheckedOut=0, UserCheckedOut=""
        if ##class(SourceControl.Git.Change).IsUncommitted(filename){
            #; Remove the item from the list of uncommitted changes;
            set sc=##class(SourceControl.Git.Change).RemoveUncommitted(filename,1,1)
            if $$$ISERR(sc) write "Error removing uncommitted file "_filename_" - "_$system.OBJ.DisplayError(sc)
        }
    }
    
    quit $$$OK
}

/// Called to add an item to source control.
Method AddToSourceControl(InternalName As %String, Description As %String = "") As %Status
{
	Quit ##class(SourceControl.Git.Utils).AddToSourceControl(InternalName)
}

}
