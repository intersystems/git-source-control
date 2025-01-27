/// Class to store information about each file that is modified by git pull
Class SourceControl.Git.Modification Extends %RegisteredObject
{

/// path of the file relative to the Git repository
Property externalName As %String;

/// Name in IRIS SourceControl.Git.Modification
Property internalName As %String;

/// Type of change (A|C|D|M|R|T|U|X|B). See git diff documentation.
Property changeType As %String;

}
