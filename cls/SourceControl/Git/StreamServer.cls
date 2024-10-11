Class SourceControl.Git.StreamServer Extends %CSP.StreamServer
{

/// The <method>OnPage()</method> is called by the CSP dispatcher to generate the
/// page content.  For %CSP.StreamServer, since the content type is actually a stream, not HTML
/// we simply write out the stream data.
ClassMethod OnPage() As %Status
{
    if (%stream '= $$$NULLOREF) && $data(%base)#2 {
        set sourceControlInclude = ##class(SourceControl.Git.Utils).GetSourceControlInclude()
        while '%stream.AtEnd {
            set text = %stream.Read()
            set text = $replace(text,"{{baseHref}}",..EscapeHTML(%base))
            write $replace(text,"{{sourceControlInclude}}",sourceControlInclude)
        }
        quit $$$OK
    }
    quit ##super()
}

}
