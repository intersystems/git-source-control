Class SourceControl.Git.Change Extends %Studio.SourceControl.Change
{

/// Returns the name of the backup file for this Item in the file system
/// Unused in this class, so override to avoid errors.
Property BackupName As %String [ Calculated, SqlComputeCode = {s {*} = ""}, SqlComputed ];

/// Returns the name of this Item in the file system
Property ExternalName As %String [ Calculated, SqlComputeCode = {S {*} = "" }, SqlComputed ];

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// Removes one or more Uncommitted items from the Uncommitted queue and changes the exported file to Readonly (except for reverts of Adds, or new CSP files within the Perforce root)
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
    if '$data(FileList) quit $$$ERROR($$$GeneralError,"No filenames were passed")
    set filename=FileList,SCs=$$$OK
    if $data(FileList)>1 set filename=$order(FileList(""))
    while (filename'="") {
        if Display write !,filename_" removed from uncommitted list"
        if '..IsUncommitted(filename) set filename=$order(FileList(filename)) continue
        set obj=..OpenUncommitted(filename)
        zwrite obj
        if (obj.Source="trakcare")&&($data(^SYS("ChangeControlClass"))) {
            set changeSourceClass=^SYS("ChangeControlClass")
        } else {
            set changeSourceClass=##class(%Studio.SourceControl.Interface).SourceControlClassGet()
        }
        if ('$get(^SYS("SourceControl","ChangeConfig","KeepHistory")))||(Revert) {
            set sc=..%DeleteId(obj.%Id())
        } else {
            if $get(CommitCCR)'="" set obj.CCR=CommitCCR
            set obj.P4Issued=$zdatetime($h,3)
            set obj.Committed=1
            set obj.ActivelyCommitted=ActiveCommit
            set obj.CommittedTime=$zdatetime($h,3)
            set sc=obj.%Save()
            if $$$ISERR(sc) do $system.Status.AppendStatus(SCs, sc) if Display do $system.Status.DisplayError(sc)
        }
        set filename=$order(FileList(filename))
    }
    quit SCs
}

/// This method records a deleted file in the uncommitted queue
ClassMethod AddDeletedToUncommitted(Filename, InternalName) As %Status
{
   
    Quit ..SetUncommitted(Filename, "delete", InternalName, $USERNAME, "", 1, "", "", 0)
}

ClassMethod IsUncommitted(Filename, ByRef ID) As %Boolean
{
    &SQL(SELECT ID INTO :ID FROM SourceControl_Git.Change WHERE ItemFile = :Filename AND Committed = '0')
    if (SQLCODE=0) {
        quit 1
    } else {
        set ID=""
        quit 0
    }
}

/// Goes through Uncommitted queue and removes any items of action 'edit' or 'add' which are ReadOnly or non-existent on the filesystem
ClassMethod RefreshUncommitted(Display = 1, IncludeRevert = 0) As %Status
{
    set sc=..ListUncommitted(.tFileList,IncludeRevert,0)
    if $$$ISERR(sc) quit sc
    set filename="", filename=$order(tFileList(filename),1,action)
    while (filename'="") {
        set examine=$select(action="add":1,action="edit":1,IncludeRevert&&(action="revert"):1,1:0)
        if 'examine set filename=$order(tFileList(filename),1,action) continue
        if ('##class(%File).Exists(filename)) {
            set sc=..RemoveUncommitted(filename,Display,0,0)
            if $$$ISERR(sc) set filename="" continue
        }
        set filename=$order(tFileList(filename),1,action)
    }
    quit sc
}

}
