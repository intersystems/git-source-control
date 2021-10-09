/// Base class for all event handlers for git pull commands.
/// Subclasses may override to perform an incremental load/compile, take no action, do a zpm "load", etc.
Class SourceControl.Git.PullEventHandler Extends %RegisteredObject
{

Parameter NAME [ Abstract ];

Parameter DESCRIPTION [ Abstract ];

/// Local git repo root directory
Property LocalRoot As %String(MAXLEN = "");

/// Modified files (integer-subscripted array, with path relative to repo root)
Property ModifiedFiles [ MultiDimensional ];

/// Modified items (InternalName format - e.g., SourceControl.Git.PullEventHandler.CLS)
/// Array is subscripted by item name
Property ModifiedItems [ MultiDimensional ];

Method OnPull() As %Status [ Abstract ]
{
}

}

