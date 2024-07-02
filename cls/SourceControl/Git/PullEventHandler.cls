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
ClassMethod ForModifications(ByRef files) As %Status
{
    set event = $classmethod(##class(SourceControl.Git.Utils).PullEventClass(),"%New")
    set event.LocalRoot = ##class(SourceControl.Git.Utils).TempFolder()
    merge event.ModifiedFiles = files
    quit event.OnPull()
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
