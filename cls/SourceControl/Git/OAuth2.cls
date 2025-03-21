Include %syPrompt

IncludeGenerator %syPrompt

Class SourceControl.Git.OAuth2 Extends %RegisteredObject
{

/// GenerateVerifier returns a cryptographically random 32 byte value
ClassMethod GenerateVerifier() As %String
{
    new $NAMESPACE
    set $NAMESPACE = "%SYS"
    return ##class(%SYSTEM.Encryption).GenCryptRand(32)
}

/// Builds the authorization code URL for the given configuration
ClassMethod AuthCodeURL(c As SourceControl.Git.OAuth2.Config, namespace As %String, Output state, Output verifier) As %String
{
    set state = namespace_"_"_..GenerateVerifier()    
    set verifier = ..GenerateVerifier()
    set url = c.AuthCodeURL(state, verifier)
    return url
}

ClassMethod GetURLsFromRemote(remote As %String, Output authCodeURL, Output tokenURL) As %Boolean
{
    if remote [ "//github.com/" {
        set authCodeURL = "https://github.com/login/oauth/authorize"
        set tokenURL = "https://github.com/login/oauth/access_token"
        return 1
    } elseif remote [ "gitlab" {
        set gitlaburl = $Piece(remote, ".com", 1) _ ".com/"
        set authCodeURL = gitlaburl _ "/oauth/authorize"
        set tokenUTL = gitlaburl _ "/oauth/token"
        return 1
    } else {
        return 0
    }
}

ClassMethod SetRemoteURLWithToken(remote As %String) As %String
{
    set token = ##class(SourceControl.Git.Util.CredentialManager).GetToken($username, .err, .code)
    if ('(remote [ token)) {
        set post = $piece($piece(remote,"https://",2),"@",2)
        set remote = "https://oauth2:"_token_"@"_post

    }
    return remote
}

}
