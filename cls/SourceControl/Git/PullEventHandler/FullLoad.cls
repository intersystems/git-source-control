Class SourceControl.Git.PullEventHandler.FullLoad Extends SourceControl.Git.PullEventHandler
{

Parameter NAME = "Full Load";

Parameter DESCRIPTION = "Performs an full load and compile of all items in the repository.";

Method OnPull() As %Status
{
    return ##class(SourceControl.Git.Utils).ImportAll(1, 
        ##class(SourceControl.Git.PullEventHandler.IncrementalLoad).%ClassName(1))
}

}
