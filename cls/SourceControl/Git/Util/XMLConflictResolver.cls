Include (%occInclude, %occErrors, %occKeyword, %occReference, %occSAX)

Class SourceControl.Git.Util.XMLConflictResolver Extends %RegisteredObject
{

Parameter ExpectedConflictTag;

Parameter OutputIndent;

Method ResolveStream(stream As %Stream.Object)
{
    // File may have:
    /*
    <<<<<<< HEAD
    <Item Name="Demo7" Category="" ClassName="EnsLib.CloudStorage.BusinessOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    =======
    <Item Name="Demo5" Category="" ClassName="EnsLib.AmazonCloudWatch.MetricAlarmOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    >>>>>>> 607d1f6 (modified src/HCC/Connect/Production.cls add Demo5)
    </Item>
    */

    // If:
    // * We have one such marker (<<<<<<< / ======= / >>>>>>>)
    // * The line after >>>>>> is "</Item>"
    // Then:
    // * We can replace ======= with "</Item>"

    Set copy = ##class(%Stream.TmpCharacter).%New()
    Set markerCount = 0
    Set postCloseMarker = 0
    While 'stream.AtEnd {
        Set line = stream.ReadLine()
        Set start = $Extract(line,1,7)
        If start = "<<<<<<<" {
            Set markerCount = markerCount + 1
            Continue
        } ElseIf (start = ">>>>>>>") {
            Set postCloseMarker = 1
            Continue
        } ElseIf (start = "=======") {
            Do copy.WriteLine(..#OutputIndent_..#ExpectedConflictTag)
            Continue
        } ElseIf postCloseMarker {
            If $ZStrip(line,"<>W") '= ..#ExpectedConflictTag {
                $$$ThrowStatus($$$ERROR($$$GeneralError,"The type of conflict encountered is not handled; user must resolve manually."))
            }
            Set postCloseMarker = 0
        }
        Do copy.WriteLine(line)
    }

    If markerCount > 1 {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"Multiple conflicts found, cannot resolve automatically."))
    } ElseIf markerCount = 0 {
        $$$ThrowStatus($$$ERROR($$$GeneralError,"No conflict markers found in file"))
    }

    $$$ThrowOnError(stream.CopyFromAndSave(copy))

    Quit 1
}

}
