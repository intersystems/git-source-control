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

Method OnPull() As %Status [ Abstract ]
{
}

}

