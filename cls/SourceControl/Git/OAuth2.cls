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

/// Gets the AuthCodeURL for github
/// namespace: is the name of the namespace that git source control is installed in
/// (we need this to ensure that we switch to the right namespace when we get the authcode from the server)
/// state -- Output : random 32 byte string to validate authCode redirects
/// verifier -- Output : random 32 byte string to validate during token exchange
ClassMethod AuthCodeURLForGithub(namespace As %String, Output state, Output verifier) As %String
{
    // (clientID As %String, clientSecret As %String, authEndpoint As %String, tokenEndpoint As %String, redirectURL As %String, scopes As %String) As %Status
    set config = ##class(SourceControl.Git.OAuth2.Config).%New(
        "Github",
        "b56623587367a6502ceb",
        "b445a726515185870c14bef647dc327ad688726b",
        "https://github.com/login/oauth/authorize",
        "https://github.com/login/oauth/access_token"    ,
        ..GetOAuthRedirectEndpoint(),
        $lb("repo"))
        
    return ..AuthCodeURL(config, namespace, .state, .verifier)
}

/// Exchanges an authorization code and associated verifier with the server and returns the retreived access_token
/// authCode: Authorization code received from github after user authenticates
/// verifier: PKCE verifier whose hash was sent to github via the authCodeURL
ClassMethod ExchangeForGithub(authCode As %String, verifier As %String, Output sc As %Status) As %String
{
    set config = ##class(SourceControl.Git.OAuth2.Config).%New(
        "Github",
        "b56623587367a6502ceb",
        "b445a726515185870c14bef647dc327ad688726b",
        "https://github.com/login/oauth/authorize",
        "https://github.com/login/oauth/access_token",
        ..GetOAuthRedirectEndpoint(),
        $lb("repo"))
    return config.Exchange(authCode, verifier, .sc)
}

/// Builds the authorization code URL for the given configuration
ClassMethod AuthCodeURL(c As SourceControl.Git.OAuth2.Config, namespace As %String, Output state, Output verifier) As %String
{
    set state = namespace_"_"_..GenerateVerifier()    
    set verifier = ..GenerateVerifier()
    set url = c.AuthCodeURL(state, verifier)
    return url
}

/// Configures all the settings requried to retreive access_tokens with oauth2
ClassMethod Configure() As %Status
{
    set defaultPromptFlag = $$$DisableBackupCharMask + $$$TrapCtrlCMask + $$$EnableQuitCharMask + $$$DisableHelpCharMask + $$$DisableHelpContextCharMask + $$$TrapErrorMask
    // get authURL
    Write !, "OAuth2 Configuration", !
    
    set response = ##class(%Library.Prompt).GetString("Enter name for client configuration:",.configName,,,,defaultPromptFlag)
    if (response '= $$$SuccessResponse) || configName = "" {
        return $$$ERROR($$$GeneralError,"Error occured when reading configuration name")
    }
    
    set redirectURL = ..GetOAuthRedirectEndpoint()
    w !, "Please configure an OAuth application with your git provider", !
    w "Be sure to whitelist this redirect URL: "_redirectURL, !
    w "Once configured, enter the following details:", !

    // get authURL
    set response = ##class(%Library.Prompt).GetString("Auth Code URL:",.authCodeURL,,,,defaultPromptFlag)
    if (response '= $$$SuccessResponse) {
        return $$$ERROR($$$GeneralError,"Error occured when reading Auth Code URL")
    }

    // get tokenURL
    set response = ##class(%Library.Prompt).GetString("Token URL:",.tokenURL,,,,defaultPromptFlag)
    if (response '= $$$SuccessResponse) {
        return $$$ERROR($$$GeneralError,"Error occured when reading Token URL")
    }

    // get clientID
    set response = ##class(%Library.Prompt).GetString("ClientID:",.clientID,,,,defaultPromptFlag)
    if (response '= $$$SuccessResponse) {
        return $$$ERROR($$$GeneralError,"Error occured when reading ClientID")
    }
    // get clientSecret
    set response = ##class(%Library.Prompt).GetString("ClientSecret:",.clientSecret,,,,defaultPromptFlag)
    if (response '= $$$SuccessResponse) {
        return $$$ERROR($$$GeneralError,"Error occured when reading ClientSecret")
    }
    
    set config = ##class(SourceControl.Git.OAuth2.Config).%New(configName, clientID, clientSecret, authCodeURL, tokenURL, redirectURL)
}

/// Returns the full URL for the oauth2.csp endpoint
ClassMethod GetOAuthRedirectEndpoint() As %String
{
    // TODO: make this dynamic
    set redirectHost = "http://localhost:52773"
    set redirectPath = "/isc/studio/usertemplates/gitsourcecontrol/oauth2.csp"
    return redirectHost_redirectPath
}

}
