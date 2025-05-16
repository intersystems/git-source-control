Class %zpkg.isc.sc.git.SSLConfig 
{

    ClassMethod CreateSSLConfigIfNonExistent(name As %String) {
        try {
            do ..CheckSSLConfig(name)
        } catch e {
            return e.AsStatus()
        }
        return $$$OK  
    }

    ClassMethod CheckSSLConfig(name As %String) [ Private, NotInheritable ] {
        $$$AddAllRoleTemporary
        new $namespace
        set $namespace = "%SYS"

        do ##class(Security.SSLConfigs).Get(name, .p)
        if $data(p) quit   

        set p("CipherList")="ALL:!aNULL:!eNULL:!EXP:!SSLv2"
        set p("CAFile")=""
        set p("CAPath")=""
        set p("CRLFile")=""
        set p("CertificateFile")=""
        set p("CipherList")="ALL:!aNULL:!eNULL:!EXP:!SSLv2"
        set p("Description")=""
        set p("Enabled")=1
        set p("PrivateKeyFile")=""
        set p("PrivateKeyPassword")=""
        set p("PrivateKeyType")=2
        set p("Protocols")=24
        set p("SNIName")=""
        set p("Type")=0
        set p("VerifyDepth")=9
        set p("VerifyPeer")=0

        do ##class(Security.SSLConfigs).Create(name, .p)
    }

}