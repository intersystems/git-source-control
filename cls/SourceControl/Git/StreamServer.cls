Class SourceControl.Git.StreamServer Extends %CSP.StreamServer
{

/// The <method>OnPage()</method> is called by the CSP dispatcher to generate the
/// page content.  For %CSP.StreamServer, since the content type is actually a stream, not HTML
/// we simply write out the stream data.
ClassMethod OnPage() As %Status
{
    if (%stream '= $$$NULLOREF) && $data(%base)#2 {
        set sourceControlInclude = ##class(SourceControl.Git.Utils).GetSourceControlInclude()
        set bodyAttrs = ##class(SourceControl.Git.Utils).ProductionConfigBodyAttributes()
        set configScript = ##class(SourceControl.Git.Utils).ProductionConfigScript()
        while '%stream.AtEnd {
            set text = %stream.Read(1000000)
            set text = $replace(text,"{{baseHref}}",..EscapeHTML(%base))
            set text = $replace(text,"{{bodyAttrs}}",bodyAttrs)
            write $replace(text,"{{sourceControlInclude}}",sourceControlInclude_$$$NL_configScript)
        }
        quit $$$OK
    }
    quit ##super()
}

}
