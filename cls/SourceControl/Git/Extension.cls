Import SourceControl.Git

Class SourceControl.Git.Extension Extends %Studio.Extension.Base
{

XData Menu
{
<MenuBase>
<Menu Name="%SourceMenu" Type="0">
<MenuItem Name="%Cache-Git-Settings" />
<MenuItem Name="%CreateRepo" Save = "001"/>
<MenuItem Name="%Clone" Save = "001"/>
<MenuItem Separator="true"/>
<MenuItem Name="%GitWebUI" Save = "111" />
<!--
<MenuItem Name="%Settings" />
<MenuItem Name="%Commit" Save = "001"/>
<MenuItem Separator="true"/>
<MenuItem Name="%Pull" Save = "001"/>
<MenuItem Name="%Fetch" Save = "001"/>
<MenuItem Name="%Switch" Save = "001"/>
<MenuItem Name="%Merge" Save = "001"/>
<MenuItem Name="%Push" Save = "001"/>
<MenuItem Separator="true"/>
<MenuItem Name="%Diff" Save = "001"/>
<MenuItem Name="%RepoStatus" Save = "001"/>
<MenuItem Name="%Resolve" Save = "001"/>
<MenuItem Name="%Revert" Save = "001"/>
<MenuItem Name="%Log" Save = "001"/>
<MenuItem Separator="true"/>
<MenuItem Name="%StashSave" Save = "001"/>
<MenuItem Name="%StashPop" Save = "001"/>
-->
<MenuItem Separator="true"/>
<MenuItem Name="%Export" Save = "001" />
<MenuItem Name="%ExportForce" Save = "001" />
<MenuItem Name="%Import" Save = "001" />
<MenuItem Name="%ImportForce" Save = "001" />
<MenuItem Separator="true"/>
<MenuItem Name="%OpenRepoFolder" Save = "001" />
<MenuItem Name="%Revert" Save = "001" />
<MenuItem Name="%Commit" Save = "001" />
<MenuItem Name="%Push" Save = "001"/>
</Menu>
<Menu Name="%SourceMenuContext" Type="1">
<MenuItem Name="%AddToSC"/>
<MenuItem Name="%RemoveFromSC"/>
<!--
<MenuItem Name="%Diff" Save = "001"/>
<MenuItem Name="%Blame" Save = "001"/>
-->
</Menu>
</MenuBase>
}

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	#dim ec As %Status = $$$OK
	#dim menu As %Status = $Piece(Name, ",", 1)
	if menu '= "%SourceMenu", menu'="%SourceMenuContext" {
		quit $$$OK
	}
	set InternalName = ##class(Utils).NormalizeInternalName(InternalName)
	set ec = ##class(Utils).UserAction(InternalName, Name, .Target, .Action, .Reload)
	quit ec
}

Method OnSourceMenuItem(name As %String, ByRef Enabled As %String, ByRef DisplayName As %String, InternalName As %String) As %Status
{
	if name = "%Cache-Git-Settings" {
		// We always show Settings
		set DisplayName = "Settings"
		quit $$$OK
	} 
	if name = "%Settings" && ##class(Utils).GitBinExists() {
		set DisplayName = "TortoiseGit Settings"
		quit $$$OK
	}
	
	if ##class(Utils).NeedSettings() {
		set Enabled = -1
		quit $$$OK
	}
	if ##class(Utils).IsNamespaceInGit() {
		if name = "%GitWebUI" {
			set DisplayName = "Launch Git UI"
		} elseif name = "%Export" {
			set DisplayName = "Export All"
		} elseif name="%ExportForce" {
			set DisplayName = "Export All Force"
		} elseif name = "%Import" {
			set DisplayName = "Import All"
		} elseif name = "%ImportForce" {
			set DisplayName = "Import All Force"
		} elseif name = "%RepoStatus" && ##class(Utils).GitBinExists() {
			set DisplayName = "Check for modifications"
		} elseif name = "%OpenRepoFolder" {
			// TODO: Only display if running locally
			set DisplayName = "Open Repo Folder"
		} elseif name = "%Revert" {
			// TODO: Only display if user has file uncommitted
			set DisplayName = "Revert Changes"
			do ..GetStatus(InternalName, .isInSourceControl, .isEditable,.isCheckedOut,.userCheckedOut)
			if '(##class(Change).IsUncommitted(##class(Utils).FullExternalName(InternalName))) || ((userCheckedOut '= "") && ($username '= userCheckedOut)) {
				set Enabled = 0
			}
		} elseif name = "%Commit" {
			// TODO: Only display if running locally
			set DisplayName = "Commit Changes"
			do ..GetStatus(InternalName, .isInSourceControl, .isEditable,.isCheckedOut,.userCheckedOut)
			if '(##class(Change).IsUncommitted(##class(Utils).FullExternalName(InternalName))) || ((userCheckedOut '= "") && ($username '= userCheckedOut)) {
				set Enabled = 0
			}
		}elseif name = "%Push" {
			// TODO: Only display if running locally
			set Enabled = 1
			set DisplayName = "Push Changes"
		}elseif ##class(Utils).IsMenuGitCommand(name) && ##class(Utils).GitBinExists() {
			set DisplayName = $case(name,"%StashSave":"Stash save",
			                             "%StashPop":"Stash pop",
			                             :$Extract(name, 2, *))
		} 
		else {
			set Enabled = -1
		}
	} elseif ##class(Utils).GitBinExists() { 
		if name = "%CreateRepo" {
			set DisplayName = "Create Repo"
		} elseif name = "%Clone" {
			set DisplayName = "Clone"
		} else {
			set Enabled = -1
		}
	} else {
		set Enabled = -1 
	}
	quit $$$OK
}

Method OnSourceMenuContextItem(itemName As %String, menuItemName As %String, ByRef Enabled As %String, ByRef DisplayName As %String) As %Status
{
	set:menuItemName="%AddToSC" DisplayName = "Add to SourceControl"
	set:menuItemName="%RemoveFromSC" DisplayName = "Remove from SourceControl"
	
	if (itemName = "") || '##class(Utils).IsNamespaceInGit() {
		set Enabled = -1
	}elseif $F(itemName,",") > 0 { //if more than one item is selected, we can only add/remove, no diff or blame
		set Enabled = $case(menuItemName,"%AddToSC":1,"%RemoveFromSC":1,:-1)
	
	}elseif ##class(Utils).IsInSourceControl(##class(Utils).NormalizeInternalName(itemName)) {
		set Enabled = $Case(menuItemName, "%AddToSC":-1,:1)
	} else {
		set Enabled = $Case(menuItemName, "%AddToSC":1,:-1)
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
	#dim menu As %String= $Piece(MenuName,",")
	#dim name As %String = $Piece(MenuName,",",2)
	if menu = "%SourceMenuContext", name = "" {
		set DisplayName = "Git"
	}
	if menu = "%SourceMenu", name = "" {
		set DisplayName = "Git"
	}
	#dim ec As %Status = $$$OK

	if menu = "%SourceMenu" {
		set ec = ..OnSourceMenuItem(name, .Enabled, .DisplayName, InternalName)
	}elseif menu = "%SourceMenuContext" {
		set ec = ..OnSourceMenuContextItem(InternalName, name, .Enabled, .DisplayName)
	}
	Quit ec
}

/// This is called before the actual load of data to give the chance
/// to load the item from an external format.
Method OnBeforeLoad(InternalName As %String) As %Status
{
	set InternalName = ##class(Utils).NormalizeInternalName(InternalName)
	if ##class(Utils).IsInSourceControl(InternalName) {
		quit ##class(Utils).ImportItem(InternalName)
	}
	quit $$$OK
}

/// This is called after the item has been saved to the database.
/// It may be passed a reference to the object representing the item
/// just saved. It can be use to export this documement to an external form for example.
/// Also, lock the file after export IF there are any changes to it
Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	set InternalName = ##class(Utils).NormalizeInternalName(InternalName)
	if ##class(Utils).IsNamespaceInGit() && ..IsInSourceControl(InternalName) {
		set filename = ##class(Utils).FullExternalName(InternalName)
		$$$QuitOnError(##class(Utils).RemoveRoutineTSH(InternalName))
		$$$QuitOnError(##class(Utils).ExportItem(InternalName))
		if '##class(SourceControl.Git.Change).IsUncommitted(filename) {
			$$$QuitOnError(##class(SourceControl.Git.Change).SetUncommitted(filename, "edit", InternalName, $Username, "", 1, "", "", 0))
		}
		quit $$$OK
	} else {
		quit $$$OK
	}
}

/// Called after the compile of the item is done.
Method OnAfterCompile(InternalName As %String) As %Status
{
	Quit ..OnAfterSave(InternalName)
}

/// Returns true if this item is in source control and false otherwise.
Method IsInSourceControl(InternalName As %String) As %Boolean [ CodeMode = expression ]
{
InternalName'="" && ##class(Utils).IsInSourceControl(##class(Utils).NormalizeInternalName(InternalName))
}

/// Called after an item is deleted.
Method OnAfterDelete(InternalName As %String) As %Status
{
	set InternalName = ##class(Utils).NormalizeInternalName(InternalName)
	if ##class(Utils).IsInSourceControl(InternalName) {
		quit ##class(Utils).DeleteExternalFile(InternalName)
	}
	quit $$$OK
}

/// Convert the internal name, e.g. TEST.MAC, to an external name that is used to export
/// the routine/class/csp item. This is often a filename to write the file out to.
Method ExternalName(InternalName As %String) As %String
{
	Quit ##class(Utils).Name(InternalName)
}

/// Check the status of the given item
/// User should be able to edit the item if it is not locked by another user
/// Check if another user has committed any changes to the item and return the status
Method GetStatus(InternalName As %String, ByRef IsInSourceControl As %Boolean, ByRef Editable As %Boolean, ByRef IsCheckedOut As %Boolean, ByRef UserCheckedOut As %String) As %Status
{
	#; Quit ##super(InternalName,.IsInSourceControl,.Editable,.IsCheckedOut,.UserCheckedOut)
		Set Editable=1,IsCheckedOut=1,UserCheckedOut=""
		Set filename=##class(SourceControl.Git.Utils).FullExternalName(InternalName)
		Set IsInSourceControl=(filename'=""&&($$$FileExists(filename)))
		If filename="" Quit $$$OK
		If InternalName="" Quit $$$OK
		#; If the file does not exist then it must be a new item so it is editable.
		If '$$$FileExists(filename) {
			Set IsCheckedOut=0
		}
		do ##class(Utils).GitStatus(.files)
		if $Get(files(InternalName)) '= "" {
			///it's in source control, checked out, and should be locked to editing by other users
			///find out who has it edited
			set IsCheckedOut=1
			Set sc=##class(SourceControl.Git.Change).GetUncommitted(filename,.tAction,.tInternalName,.UncommittedUser,.tSource,.UncommittedLastUpdated)
			If $$$ISOK(sc) && ($D(tAction)&&(UncommittedUser'=$USERNAME)) {
				Set msg="NOTICE: "_InternalName_" is currently checked out by user '"_UncommittedUser_"', and was last updated at "_UncommittedLastUpdated
				Write !,msg
				Set Editable=0
				Set IsInSourceControl=0		;set this to 0 to prevent user from being prompted to Check Out file
				Set UserCheckedOut=UncommittedUser
			} 
		}
		// If it doesn't show up in git status, there are no uncommitted changes so it should not be locked or checked out by any user
		else { 
			set Editable=1, IsCheckedOut=0, UserCheckedOut=""
			if ##class(SourceControl.Git.Change).IsUncommitted(filename){
				#; Remove the item from the list of uncommitted changes; 
				Set sc=##class(SourceControl.Git.Change).RemoveUncommitted(filename,1,1)
				If $$$ISERR(sc) Write "Error removing uncommitted file "_filename_" - "_$System.OBJ.DisplayError(sc)
			}
		}
		
		Quit $$$OK
}

}

