Class SourceControl.Git.Change Extends %Studio.SourceControl.Change
{

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// Removes one or more Uncommitted items from the Uncommitted queue and changes the exported file to Reaonly (except for reverts of Adds, or new CSP files within the Perforce root)
/// <P> Default assumed behavior is that the the change was not reverted, and that it was actively committed to Perforce
/// <P> If the method calling does not know whether it was reverted or committed to Perforce, then it should pass <var>Revert</var> = 0 and <var>ActiveCommit</var> = 0, 
/// indicating that the change might have been reverted and the Perforce history should be checked for the definitive answer.
/// <P>The <var>Revert</var>, <var>ActiveCommit</var>, and <var>CommitCCR</var> arguments only impact the behavior if <code>^SYS("SourceControl","ChangeConfig","KeepHistory")=1</code>, 
/// which means Change objects should have their Committed flag set to 1 and be saved for historical reference, rather than just deleting the Change objects
/// when RemoveUncommitted() is called.
/// <p> Arguments are as follows:
/// <ul>
/// <li><var>FileList</var> - the name of the file to revert, or an array subscripted by filenames (e.g. <code>FileList("C:\Perforce\custom_ccrs\us\ISCX\TESTSYS\cls\User\Test.xml")=""</code>)</li>
/// <li><var>Display</var> - boolean flag controlling whether to display the results to standard output (defaults to '1')</li>
/// <li><var>Revert</var> - boolean flag controlling whether to revert a checkout which would delete the change from the change history table (defaults to '0')</li>
/// <li><var>ActiveCommit</var> - used for historical tracking purposes for the %Studio_SourceControl.Change table</li>
/// <li><var>CommitCCR</var> - used for historical tracking purposes for the %Studio_SourceControl.Change table</li>
/// </ul>
ClassMethod RemoveUncommitted(FileList, Display = 1, Revert = 0, ActiveCommit = 1, CommitCCR) As %Status
{
	If '$DATA(FileList) Quit $$$ERROR($$$GeneralError,"No filenames were passed")
	Set filename=FileList,SCs=$$$OK
	If $DATA(FileList)>1 Set filename=$ORDER(FileList(""))
	While (filename'="") {
		If Display Write !,filename_" removed from uncommitted list"
		If '..IsUncommitted(filename) Set filename=$ORDER(FileList(filename)) continue
		Set obj=..OpenUncommitted(filename)
		If (obj.Source="trakcare")&&($D(^SYS("ChangeControlClass"))) {
			Set changeSourceClass=^SYS("ChangeControlClass")
		} Else {
			Set changeSourceClass=##class(%Studio.SourceControl.Interface).SourceControlClassGet()
		}
		If ('$G(^SYS("SourceControl","ChangeConfig","KeepHistory")))||(Revert) {
			Set sc=..%DeleteId(obj.%Id())
		} Else {
			If $G(CommitCCR)'="" Set obj.CCR=CommitCCR
			Set obj.P4Issued=$zdt($H,3)
			Set obj.Committed=1	
			Set obj.ActivelyCommitted=ActiveCommit
			Set obj.CommittedTime=$zdt($H,3)
			Set sc=obj.%Save()
			If $$$ISERR(sc) Do $SYSTEM.Status.AppendStatus(SCs, sc) If Display Do $System.Status.DisplayError(sc)
		}
		Set filename=$ORDER(FileList(filename))
	}
	Quit SCs
}

ClassMethod IsUncommitted(Filename, ByRef ID) As %Boolean
{
	&sql(SELECT ID into :ID FROM SourceControl_Git.Change WHERE ItemFile = :Filename AND Committed = '0')
	If (SQLCODE=0) {
		Quit 1
	} Else {
		Set ID=""
		Quit 0
	}
}

/// Goes through Uncommitted queue and removes any items of action 'edit' or 'add' which are ReadOnly or non-existent on the filesystem
ClassMethod RefreshUncommitted(Display = 1, IncludeRevert = 0) As %Status
{
	Set sc=..ListUncommitted(.tFileList,IncludeRevert,0)
	If $$$ISERR(sc) Quit sc
	Set filename="", filename=$ORDER(tFileList(filename),1,action)
	While (filename'="") {
		Set examine=$Select(action="add":1,action="edit":1,IncludeRevert&&(action="revert"):1,1:0)
		If 'examine Set filename=$ORDER(tFileList(filename),1,action) continue
		If ('##class(%File).Exists(filename)) {
			Set sc=..RemoveUncommitted(filename,Display,0,0)	
			If $$$ISERR(sc) s filename="" continue
		}
		Set filename=$ORDER(tFileList(filename),1,action)
	}
	Quit sc
}

}
