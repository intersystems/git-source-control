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

/// Configures all the settings requried to retreive access_tokens with oauth2
ClassMethod Configure(remote As %String = "") As SourceControl.Git.OAuth2.Config
{
    // TODO-etamarch -> This needs way more explanation of what is what. Maybe autodetect if using 
    //          github / gitlab and point to necessary information / docs / explain some of the inputs

    set config = ##class(SourceControl.Git.OAuth2.Config).GetConfig($username)

    if (config = "") {
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

        set urls =  ..GetURLsFromRemote(remote, .authCodeURL, .tokenURL)

        if ('urls) {

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
    return config
}

/// Returns the full URL for the oauth2.csp endpoint
ClassMethod GetOAuthRedirectEndpoint() As %String
{
    // TODO-etamarch: make this dynamic
    //   How do we get the hostname????
    set redirectHost = "http://localhost:52776"
    set redirectPath = "/isc/studio/usertemplates/gitsourcecontrol/oauth2.csp"
    return redirectHost_redirectPath
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

ClassMethod GetRemoteURLWithToken(token As %String) As %String
{
    set remote = ""
    set url = ##class(SourceControl.Git.Utils).GitRemoteURL()
    if url [ "//github.com/" {
        set remote = "https://"_token_"@github.com"_$piece(url, "github.com", 2)
    } elseif url [ "gitlab" {
        set remote = "https://oauth2:"_token_"@gitlab.com"_$piece(url,"https://",2)
    }
    return remote
}

}
