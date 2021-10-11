Class SourceControl.Git.API
{

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

}

