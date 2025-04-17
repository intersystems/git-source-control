Include SourceControl.Git

Class SourceControl.Git.Change Extends (%Persistent, %Studio.SourceControl.Change)
{

/// Returns the name of the backup file for this Item in the file system
/// Unused in this class, so override to avoid errors.
Property BackupName As %String [ Calculated, SqlComputeCode = {s {*} = ""}, SqlComputed ];

/// Returns the name of this Item in the file system
Property ExternalName As %String [ Calculated, SqlComputeCode = {S {*} = "" }, SqlComputed ];

Index CommittedMap On Committed [ Type = bitmap ];

Index ChangeList On (ItemFile, CommittedTime) [ Data = Action, Unique ];

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
ClassMethod RemoveUncommitted(FileList, Display As %Boolean = 1, Revert As %Boolean = 0, ActiveCommit As %Boolean = 1, CommitCCR As %String) As %Status
{
    if '$data(FileList) quit $$$ERROR($$$GeneralError,"No filenames were passed")
    set filename=FileList,SCs=$$$OK
    if $data(FileList)>1 set filename=$order(FileList(""))
    while (filename'="") {
        if Display write !,filename_" removed from uncommitted list"
        if '..IsUncommitted(filename) set filename=$order(FileList(filename)) continue
        set obj=..OpenUncommitted(filename)
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

/// The Filename here is an ExternalName formatted name with the full file path
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

ClassMethod GetOtherDeveloperChanges() As %Boolean
{
    set numEntries = 0
    set fileToOtherDevelopers = {}

    set username = $username
    &sql(DECLARE DeveloperCursor CURSOR FOR SELECT ItemFile, ChangedBy into :itemFile, :changedBy from SourceControl_Git.Change WHERE Committed = 0 and ChangedBy <> :username)
    &sql(OPEN DeveloperCursor)
        throw:SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
    &sql(FETCH DeveloperCursor)
    set tempFolder = ##class(SourceControl.Git.Utils).TempFolder()
    while(SQLCODE = 0) {
        if $FIND(itemFile, tempFolder) {
            set filePath = $PIECE(itemFile, tempFolder, 2)
            set otherDevelopers = fileToOtherDevelopers.%Get(filePath, [])
            do otherDevelopers.%Push(changedBy)
            do fileToOtherDevelopers.%Set(filePath, otherDevelopers)
        }
        
        &sql(FETCH DeveloperCursor)
    }
    &sql(CLOSE DeveloperCursor)

    return fileToOtherDevelopers
}

/// Goes through Uncommitted queue and removes any items of action 'edit' or 'add' which are ReadOnly or non-existent on the filesystem
ClassMethod RefreshUncommitted(Display As %Boolean = 0, IncludeRevert As %Boolean = 0, Output gitFiles, Force As %Boolean = 0) As %Status
{
    
    set lock = $System.AutoLock.Lock("^SourceControl.Git.Refresh",,10)
    if lock = $$$NULLOREF {
        quit $$$ERROR($$$GeneralError,"Unable to get exclusive lock for refresh of uncommitted changes.")
    }
    if 'Force {
        // 10-second throttle on RefreshUncommitted
        if $zdatetime($ztimestamp,-2) - $Get(^IRIS.Temp.gitsourcecontrol("Refresh"),0) < 10 {
            merge gitFiles = ^IRIS.Temp.gitsourcecontrol("LastUncommitted")
            quit $$$OK
        }
    }
    kill gitFiles
    
    // files from the uncommitted queue
    set sc=..ListUncommitted(.tFileList,IncludeRevert,0)
    if $$$ISERR(sc) quit sc

    // files from git status
    do ##class(Utils).GitStatus(.gitFiles)

    // Remove entries in the uncommitted queue that don't correspond to changes as tracked by git
    set filename=""
    for {
        set filename=$order(tFileList(filename),1,action)
        quit:filename=""

        set examine=$select(action="add":1,
            action="edit":1,
            action="delete":1,
            IncludeRevert&&(action="revert"):1,
            1:0)
        if 'examine {
            continue
        }

        set packageRoot = ##class(SourceControl.Git.Utils).TempFolder()
        set InternalName = ##class(SourceControl.Git.Utils).NameToInternalName(filename,0,0)

        // skip files belonging to other git enabled packages
        if ($EXTRACT(filename, 1, $LENGTH(packageRoot)) '= packageRoot) continue

        if (('##class(%File).Exists(filename)) || (InternalName = "") || ((InternalName '= "") && ('$data(gitFiles(InternalName), found)) && 
            (($data($$$TrackedItems(InternalName))) || ##class(SourceControl.Git.Utils).NormalizeExtension($data($$$TrackedItems(InternalName))))))  {
            set sc=..RemoveUncommitted(filename,Display,0,0)
            if $$$ISERR(sc) continue
        }
    }

    // Add missing records to the uncommitted queue that correspond to changes as tracked by git
    set filename=""
    for {
        set filename=$order(gitFiles(filename),1,details)
        quit:filename=""
        
        set InternalName = filename
        set ExternalName = ##class(%File).NormalizeFilename(##class(SourceControl.Git.Utils).TempFolder()_$list(details,2))
        set changeType = $list(details,1)

        set action = $select(changeType="A":"add", 
                             changeType="M":"edit",
                             changeType="D":"delete",
                             changeType="U":"add",
                             1:"add")

        if ((##class(%File).Exists(ExternalName)) && ('$ISVALIDNUM(InternalName)) && ('..IsUncommitted(ExternalName)) && ($data($$$TrackedItems(InternalName))))  {
            set sc=..SetUncommitted(ExternalName, action, InternalName, $USERNAME, "", 1, "", "", 0)
            if $$$ISERR(sc) continue
        }
    }

    // If a file was added to the index and then deleted, git status will show it as a delete but committing will fail.
    // The solution is to git add each deleted file that has never been committed so it will be removed from the index.
    set key = $order(gitFiles(""))
    while (key '= "") {
        if $listget(gitFiles(key),1) = "D" {
            set filename = $listget(gitFiles(key),2)
            do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("log",,.errStream,.outStream,"--first-parent", "--", filename)
            if (outStream.Size = 0) {
                do ##class(SourceControl.Git.Utils).RunGitCommandWithInput("add",,errStream,outStream,filename)
            }
        }
        set key = $order(gitFiles(key))
    }
    set ^IRIS.Temp.gitsourcecontrol("Refresh") = $zdatetime($ztimestamp,-2)
    merge ^IRIS.Temp.gitsourcecontrol("LastUncommitted") = gitFiles
    quit sc
}

Query InstanceUncommitted() As %Query(ROWSPEC = "InternalName:%String,User:%String,Namespace:%String")
{
}

ClassMethod InstanceUncommittedExecute(ByRef qHandle As %Binary) As %Status
{
    set initNS = $namespace
    &sql(DECLARE InstanceCursor CURSOR FOR SELECT InternalName, ChangedBy into :internalName, :changedBy from SourceControl_Git.Change)
    set namespaces = ##class(SourceControl.Git.Utils).GetGitEnabledNamespaces()
    set tPtr = 0
    set qHandle("i") = 1
    new $namespace
    kill ^||InstanceUncommitted
    while $LISTNEXT(namespaces, tPtr, tValue) {
        set namespace = $ZCONVERT(tValue, "U")
        if '(namespace [ "^") && (namespace '= initNS) {
            set $NAMESPACE = namespace
                
                &sql(OPEN InstanceCursor)
                    throw:SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
                &sql(FETCH InstanceCursor)
                while(SQLCODE = 0) {
                    set ^||InstanceUncommitted("changes", $increment(^||InstanceUncommitted("changes")), "InternalName") = internalName
                    set ^||InstanceUncommitted("changes", ^||InstanceUncommitted("changes"), "User") = changedBy
                    set ^||InstanceUncommitted("changes", ^||InstanceUncommitted("changes"), "Namespace") = namespace
                    &sql(FETCH InstanceCursor)
                }
                &sql(CLOSE InstanceCursor)
        }
    }
    
    Quit $$$OK
}

ClassMethod InstanceUncommittedFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = InstanceUncommittedExecute ]
{
    set i = qHandle("i")
    if $data(^||InstanceUncommitted("changes",i))=10 {
        set Row = $listbuild(^||InstanceUncommitted("changes", i, "InternalName"), ^||InstanceUncommitted("changes", i, "User"), ^||InstanceUncommitted("changes", i, "Namespace"))
    }
    if i >= $get(^||InstanceUncommitted("changes"),0) {
        set AtEnd = 1
    } else {
        set qHandle("i") = $increment(qHandle("i"))
    }
    Quit $$$OK
}

Storage Default
{
<Data name="ChangeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Action</Value>
</Value>
<Value name="3">
<Value>Committed</Value>
</Value>
<Value name="4">
<Value>CommittedTime</Value>
</Value>
<Value name="5">
<Value>CCR</Value>
</Value>
<Value name="6">
<Value>InternalName</Value>
</Value>
<Value name="7">
<Value>ItemFile</Value>
</Value>
<Value name="8">
<Value>Name</Value>
</Value>
<Value name="10">
<Value>Source</Value>
</Value>
<Value name="11">
<Value>UpdatedTime</Value>
</Value>
<Value name="12">
<Value>ChangedBy</Value>
</Value>
<Value name="13">
<Value>ActivelyCommitted</Value>
</Value>
<Value name="14">
<Value>P4Issued</Value>
</Value>
</Data>
<DataLocation>^Studio.SourceControl.ChangeD</DataLocation>
<DefaultData>ChangeDefaultData</DefaultData>
<IdLocation>^Studio.SourceControl.ChangeD</IdLocation>
<IndexLocation>^Studio.SourceControl.ChangeI</IndexLocation>
<StreamLocation>^Studio.SourceControl.ChangeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

