Class SourceControl.Git.StreamServer Extends %CSP.StreamServer
{

/// The <method>OnPage()</method> is called by the CSP dispatcher to generate the
/// page content.  For %CSP.StreamServer, since the content type is actually a stream, not HTML
/// we simply write out the stream data.
ClassMethod OnPage() As %Status
{
	if (%stream '= $$$NULLOREF) && $data(%base)#2 { 
        while '%stream.AtEnd {
            write $Replace(%stream.Read(),"{{baseHref}}",..EscapeHTML(%base))
        }
        quit $$$OK
    }
	Quit ##super()
}

}

