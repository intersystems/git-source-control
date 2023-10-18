Class SourceControl.Git.OAuth Extends %RegisteredObject
{

Property ClientID As %String;

Property ClientSecret As %String;

Method %OnNew() As %Status
{
    set i%ClientSecret = "b445a726515185870c14bef647dc327ad688726b"
    set i%ClientID = "b56623587367a6502ceb"
}

// GenerateVerifier returns a cryptographically random 32 byte value

ClassMethod GenerateVerifier() As %String
{
    new $NAMESPACE
    set $NAMESPACE = "%SYS"
    return ##class(%SYSTEM.Encryption).GenCryptRand(32)
}

ClassMethod AuthCodeURLForGithub(namespace As %String, Output state, Output verifier) As %String
{
    // (clientID As %String, clientSecret As %String, authEndpoint As %String, tokenEndpoint As %String, redirectURL As %String, scopes As %String) As %Status
    set config = ##class(SourceControl.Git.OAuth2.Config).%New(
        "b56623587367a6502ceb",
        "b445a726515185870c14bef647dc327ad688726b",
        "https://github.com/login/oauth/authorize",
        "https://github.com/login/oauth/access_token"    ,
        "http://localhost:52773/isc/studio/usertemplates/gitsourcecontrol/oauth.csp/",
        $lb("repo"))
        
    return ..AuthCodeURL(config, namespace, .state, .verifier)
}

ClassMethod ExchangeForGithub(authCode As %String, verifier As %String, Output sc As %Status) As %String
{
    set config = ##class(SourceControl.Git.OAuth2.Config).%New(
        "b56623587367a6502ceb",
        "b445a726515185870c14bef647dc327ad688726b",
        "https://github.com/login/oauth/authorize",
        "https://github.com/login/oauth/access_token",
        "http://localhost:52773/isc/studio/usertemplates/gitsourcecontrol/oauth.csp/",
        $lb("repo"))
    return config.Exchange(authCode, verifier, .sc)
}

ClassMethod AuthCodeURL(c As SourceControl.Git.OAuth2.Config, namespace As %String, Output state, Output verifier) As %String
{
    set state = namespace_"_"_..GenerateVerifier()    
    set verifier = ..GenerateVerifier()
    set url = c.AuthCodeURL(state, verifier)
    return url
}

ClassMethod Configure() As %Status
{
}

Method FetchCredentials(username As %String)
{
}

}
