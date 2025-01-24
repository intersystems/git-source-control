/// Base class for all event handlers for git pull commands.
/// Subclasses may override to perform an incremental load/compile, take no action, do a zpm "load", etc.
Class SourceControl.Git.PullEventHandler Extends %RegisteredObject
{

Parameter NAME [ Abstract ];

Parameter DESCRIPTION [ Abstract ];

/// Local git repo root directory
Property LocalRoot As %String(MAXLEN = "");

/// Modified files (integer-subscripted array storing objects of class SourceControl.Git.Modification)
Property ModifiedFiles [ MultiDimensional ];

/// The branch that is checked out before OnPull() is called
Property Branch [ InitialExpression = {##class(SourceControl.Git.Utils).GetCurrentBranch()} ];

Method OnPull() As %Status [ Abstract ]
{
}

/// <var>files</var> is an integer-subscripted array of <class>SourceControl.Git.Modification</class> objects.
/// <var>pullEventClass</var>: if defined, override the configured pull event class
ClassMethod ForModifications(ByRef files, pullEventClass As %String) As %Status
{
    set log = ##class(SourceControl.Git.DeploymentLog).%New()
    set log.HeadRevision = ##class(SourceControl.Git.Utils).GetCurrentRevision()
    set log.StartTimestamp = $zdatetime($ztimestamp,3)
    do log.%Save()
    set event = $classmethod(
        $select(
            $data(pullEventClass)#2: pullEventClass, 
            1: ##class(SourceControl.Git.Utils).PullEventClass())
        ,"%New")
    set event.LocalRoot = ##class(SourceControl.Git.Utils).TempFolder()
    merge event.ModifiedFiles = files
    set st = event.OnPull()
    set log.EndTimestamp = $zdatetime($ztimestamp,3)
    set log.Status = st
    do log.%Save()
    quit st
}

/// <var>InternalName</var> may be a comma-delimited string or $ListBuild list
ClassMethod ForInternalNames(InternalName As %String) As %Status
{
    set list = $select($listvalid(InternalName):InternalName,1:$ListFromString(InternalName))
    set pointer = 0
    while $listnext(list,pointer,InternalName) {
        set mod = ##class(SourceControl.Git.Modification).%New()
        set mod.internalName = InternalName
        set mod.externalName = ##class(SourceControl.Git.Utils).FullExternalName(InternalName)
        set mod.changeType = "M"
        set files($i(files)) = mod
    }
    quit ..ForModifications(.files)
}

}
