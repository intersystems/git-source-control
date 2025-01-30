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
<MenuItem Name="GitWebUI" Save="101" />
<MenuItem Separator="true"/>
<MenuItem Name="AddToSC" Save="100" />
<MenuItem Name="RemoveFromSC"/>
<MenuItem Name="Revert" Save="100" />
<MenuItem Name="Commit" Save="100" />
<MenuItem Separator="true"/>
<MenuItem Name="Sync" Save="101" />
<MenuItem Name="Push" />
<MenuItem Name="PushForce" />
<MenuItem Name="Fetch" Save="101" />
<MenuItem Name="Pull" Save="101" />
<MenuItem Separator="true"/>
<MenuItem Name="NewBranch" Save="101" />
<MenuItem Name="SwitchBranch" Save="101" />
<MenuItem Separator="true"/>
<MenuItem Name="ExportSystemDefaults" />
<MenuItem Name="ExportProduction" />
<MenuItem Name="Export" Save="101" />
<MenuItem Name="ExportForce" Save="101" />
<MenuItem Name="Import" />
<MenuItem Name="ImportForce" />
</Menu>
<Menu Name="%SourceContext" Type="1">
<MenuItem Name="AddToSC" Save="100" />
<MenuItem Name="RemoveFromSC"/>
<MenuItem Name="Revert" Save="100" />
<MenuItem Name="Commit" Save="100" />
</Menu>
</MenuBase>
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
    set settings = ##class(SourceControl.Git.Settings).%New()
    // If namespace change event
    if Type = 1, Name = 5 {
        // reroute to Status menu option
        set Name = "%SourceMenu,Status"
        do ..CheckCommitterIdentity(settings, .Action, .Target)
    }

    if (Type = 1) && (Name = 3) {
        set filename = ##class(SourceControl.Git.Utils).FullExternalName(.InternalName)
        do ##class(SourceControl.Git.Change).GetUncommitted(filename,.tAction)
        do ..GetStatus(.InternalName, .isInSourceControl, .isEditable,.isCheckedOut,.userCheckedOut)

        // Deal with Business Processes and Rules
        // Note: Business Processes and Rules do not have a 'new document' User Action, and thus must be added like this
        if (('isInSourceControl)) {
            do ..CheckBusinessProcessesAndRules(InternalName)
        }

        if '$data(tAction) {
            set user = "", inNamespace = ""
            if 'isEditable || ##class(SourceControl.Git.Utils).Locked() {
                set Target = "Warning: Attempting to edit read-only file"
                write !, Target
                set Action = 6
            } elseif settings.warnInstanceWideUncommitted 
                    && '(##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(InternalName))
                    && ##class(SourceControl.Git.Utils).InstanceWideUncommittedCheck(InternalName, .user, .inNamespace) {
                // if item is being edited in a different namespace, opening it will display an alert. Editing in this namespace will remove the alert.
                set Target = "Warning: Item " _ InternalName _ " is currently being modified by " _ user _ " in namespace " _ inNamespace _ "."
                write !, Target
                set Action = 6
            } 
        }
    }

    if (Type = 1) && ((Name = 1) || (Name = 7)) {
        do ..AddToSourceControl(InternalName)
    }
    

    #dim ec as %Status = $$$OK
    #dim menu as %Status = $piece(Name, ",", 1)
    #dim menuItemName as %String = $piece(Name,",",2)
    if menu '= "%SourceMenu", menu'="%SourceContext" {
        quit $$$OK
    }

    if (menuItemName = "Commit") {
        set defaultBasic = ##class(SourceControl.Git.Utils).InDefaultBranchBasicMode()
        if (defaultBasic) {
            Set Target = "WARNING: Please create a new branch before committing."
            set Action = 6
            quit $$$OK
        }
    }

    if (menuItemName = "Commit") || (menuItemName = "Sync") {
        if ..CheckCommitterIdentity(settings, .Action, .Target) {
            quit $$$OK
        }
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
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName, .fromWebApp)
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    set ec = ##class(SourceControl.Git.Utils).AfterUserAction(Type, Name, InternalName, .Answer, .Msg, .Reload)
    if fromWebApp {
        // Force reload and compile of actual item if underlying file has changed
        do ..OnBeforeLoad(InternalName,1,1)
    }
    quit ec
}

Method LocalizeName(name As %String) As %String
{
    quit $case(name,
        "Settings":$$$Text("@Settings@Settings"),
        "Init":$$$Text("@Init@Initialize"),
        "GitWebUI":$$$Text("@GitWebUI@Launch Git UI"),
        "ExportSystemDefaults":$$$Text("@ExportSystemDefaults@Export System Default Settings"),
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
        "PushForce":$$$Text("@PushForce@Push to remote branch (Force)"),
        "Fetch":$$$Text("@Fetch@Fetch from remote"),
        "Pull":$$$Text("@Pull@Pull changes from remote branch"),
        "Status": $$$Text("@Status@Status"),
        "ExportProduction": $$$Text("@ExportProduction@Export Production"),
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

        if $listfind($listbuild("AddToSC", "RemoveFromSC", "Revert", "Commit", "ExportProduction"), name) {
            quit ..OnSourceMenuContextItem(InternalName,name,.Enabled,.DisplayName)
        }

        if name = "ExportSystemDefaults" {
            set Enabled = ##class(%Library.EnsembleMgr).IsEnsembleNamespace()
            quit $$$OK
        }

        if ##class(SourceControl.Git.Utils).BasicMode() {
            set Enabled = $CASE(name,
                "Status": 1,
                "GitWebUI" : 1,
                "Import": 1,
                "ImportForce": 1,
                "NewBranch": 1,
                "SwitchBranch": 1,
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
                "PushForce": 1,
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
    } elseif (name '= "") {
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
    } elseif menuItemName = "ExportProduction" {
        set itemNameNoExt = $piece(itemName,".",1,*-1)
        set Enabled = (##class(SourceControl.Git.Production).IsProductionClass(itemNameNoExt,"FullExternalName"))
    } elseif ##class(SourceControl.Git.Utils).IsInSourceControl(itemName) {
        set Enabled = $case(menuItemName, "AddToSC":-1,:1)
    } else {
        if (##class(SourceControl.Git.Utils).Type(itemName) = "cls") && ('$$$defClassDefined($extract(itemName, 1, $length(itemName) - 4))) {
            set Enabled = -1
        } else {
            set Enabled = $case(menuItemName, "AddToSC":1,:-1)
        }
    }
    if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(itemName) && ((menuItemName = "AddToSC") || (menuItemName = "RemoveFromSC")) {
        set Enabled = -1
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
Method OnBeforeLoad(InternalName As %String, verbose As %Boolean, compile As %Boolean = 0) As %Status
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
    set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(InternalName)
    if ##class(SourceControl.Git.Utils).IsInSourceControl(InternalName) {
        quit ##class(SourceControl.Git.Utils).ImportItem(InternalName,,0,compile)
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
    quit:$get(%gscSkipSaveHooks) sc
    try {
        set InternalName = ##class(SourceControl.Git.Utils).NormalizeInternalName(.InternalName,.fromWebApp,.fullExternalName)
        set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(InternalName)
        if ##class(SourceControl.Git.Utils).IsNamespaceInGit() {
            // If this is a production class and production decomposition is enabled, call recursively on all modified production items.
            if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(InternalName) {
                do ##class(SourceControl.Git.Production).GetModifiedItemsAfterSave(InternalName, .productionItems)
                set key = $order(productionItems(""))
                while (key '= "") {
                    if productionItems(key) = "D" {
                        set itemFilename = ..FullExternalName(key)
                        if ##class(SourceControl.Git.Utils).IsInSourceControl(key) && ##class(%File).Exists(itemFilename) {
                            $$$ThrowOnError(##class(SourceControl.Git.Change).AddDeletedToUncommitted(itemFilename, key))
                            $$$ThrowOnError(##class(SourceControl.Git.Utils).DeleteExternalFile(key))
                        }
                    } elseif '..IsInSourceControl(key) {
                        $$$ThrowOnError(##class(SourceControl.Git.Utils).AddToSourceControl(key,0))
                    } else {
                        $$$ThrowOnError(..OnAfterSave(key))
                    }
                    set key = $order(productionItems(key))
                }
                if $data(productionItems) {
                    do ##class(SourceControl.Git.Change).RefreshUncommitted(,,,1)
                }
            } elseif ..IsInSourceControl(InternalName) {
                if fromWebApp {
                    if fullExternalName = ##class(SourceControl.Git.Utils).FullExternalName(InternalName) {
                        // Reimport item into database
                        $$$ThrowOnError(##class(SourceControl.Git.Utils).ImportItem(InternalName,,1,1))
                    }
                } else {
                    set filename = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
                    $$$ThrowOnError(##class(SourceControl.Git.Utils).RemoveRoutineTSH(InternalName))
                    set forceExport = (InternalName'= "") && ($data(..Modified(InternalName)))
                    $$$ThrowOnError(##class(SourceControl.Git.Utils).ExportItem(InternalName,,forceExport))
                    if '##class(SourceControl.Git.Change).IsUncommitted(filename) {
                        $$$ThrowOnError(##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", InternalName, $username, "", 1, "", "", 0))
                    }
                }
            } else {
                do ..CheckBusinessProcessesAndRules(InternalName)
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
    set settings = ##class(SourceControl.Git.Settings).%New()
    quit (##class(SourceControl.Git.Utils).Locked() 
            && '$get(^IRIS.Temp("sscProd",$job,"bypassLock")))
        || (##class(SourceControl.Git.Utils).ItemIsProductionToDecompose($get(InternalName))
            && 'settings.decomposeProdAllowIDE
            && '##class(SourceControl.Git.Production).IsEnsPortal())
}

/// Called before the item is saved to the database it is passed
/// a reference to the current temporary storage of this item so that it
/// can be modified before the save completes. If you quit with an error
/// value then it will abort the save.
Method OnBeforeSave(InternalName As %String, Location As %String = "", Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
    set st = $$$OK
    if ##class(SourceControl.Git.Utils).ItemIsProductionToDecompose(InternalName) {
        do ##class(SourceControl.Git.Production).GetModifiedItemsBeforeSave(InternalName,,.productionItems)
		set key = $order(productionItems(""))
		while (key '= "") {
			// if any modified items in this production class are checked out by a different user, fail the check.
			set st = ..GetStatus(key, .IsInSourceControl, .Editable, .IsCheckedOut, .UserCheckedOut)
            quit:$$$ISERR(st)
			if 'Editable set st = $$$ERROR($$$GeneralError,"Item is checked out by another user: "_UserCheckedOut)
            quit:$$$ISERR(st)
			set key = $order(productionItems(key))
		}
    }
    return st
}

/// Check the status of the given item
/// User should be able to edit the item if it is not locked by another user
/// Check if another user has committed any changes to the item and return the status
Method GetStatus(ByRef InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
    set context = ##class(SourceControl.Git.PackageManagerContext).ForInternalName(.InternalName)
    set Editable='..IsReadOnly($get(InternalName)),IsCheckedOut=1,UserCheckedOut=""
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

/// Called to check if committer identity is configured.
Method CheckCommitterIdentity(Settings As SourceControl.Git.Settings, ByRef Action As %String, ByRef Target As %String) As %Boolean
{
    if ((Settings.gitUserName = "") || (Settings.gitUserEmail = "")) {
        set Target = "Git committer name or email is not configured. Go to the Settings page in the Source Control menu to fix this."
        set Action = 6
        return 1
    }
    return 0
}

/// Deal with Business Processes and Rules
Method CheckBusinessProcessesAndRules(InternalName As %String) As %Status
{
    // Note: Business Processes and Rules are not added through normal user action processes because of upstream hook issues,
    //       so we have to add them like this
    if (##class(SourceControl.Git.Utils).Type(InternalName) = "cls") {
        set name = $piece(InternalName,".CLS",1)
        set exists = ##class(%Dictionary.CompiledClass).%ExistsId(name)
        if (exists && ($classmethod(name,"%Extends","Ens.BusinessProcess") || $classmethod(name,"%Extends","Ens.Rule.Definition"))) {
            do ..AddToSourceControl(InternalName)
        }
    }
}

}
