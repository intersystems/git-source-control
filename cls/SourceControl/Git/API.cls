Class SourceControl.Git.API
{

/// Configures settings for Git integration
ClassMethod Configure()
{
    set sc = $$$OK
    set initTLevel = $TLevel
    try {
        TSTART
        $$$ThrowOnError(##class(%Studio.SourceControl.Interface).SourceControlClassSet("SourceControl.Git.Extension"))
        write !,"Configured SourceControl.Git.Extension as source control class for namespace ",$namespace
        set mappingsNode = ##class(SourceControl.Git.Utils).MappingsNode()
        if '$Data(@mappingsNode) {
            set @mappingsNode@("CLS","*")="cls/"
            set @mappingsNode@("CLS","UnitTest")="test/"
            set @mappingsNode@("INC","*")="inc/"
            set @mappingsNode@("MAC","*")="rtn/"
            write !,"Configured default mappings for classes, routines, and include files. You can customize these in the global:",!?5,mappingsNode
        }
        set good = ##class(SourceControl.Git.Settings).Configure()
        if 'good {
            write !,"Cancelled."
            quit
        }
        TCOMMIT
    } catch e {
        set sc = e.AsStatus()
        write !,$System.Status.GetErrorText(sc)
    }
    while $TLevel > initTLevel {
        TROLLBACK 1
    }
}

/// API for git pull - just wraps Utils
ClassMethod Pull()
{
    quit ##class(SourceControl.Git.API).Pull()
}

/// Locks the environment to prevent changes to code other than through git pull.
/// Returns 1 if the environment was already locked, 0 if it was previously unlocked.
ClassMethod Lock()
{
    quit ##class(SourceControl.Git.Utils).Locked(1)
}

/// Unlocks the environment to allow changes through the IDE.
/// Returns 1 if the environment was already locked, 0 if it was previously unlocked.
ClassMethod Unlock()
{
    quit ##class(SourceControl.Git.Utils).Locked(0)
}

}

