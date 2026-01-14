Include %syPrompt

IncludeGenerator %syPrompt

Class SourceControl.Git.OAuth2 Extends %RegisteredObject
{

/// GenerateVerifier returns a cryptographically random string compliant with RFC 7636 (PKCE)
/// Requirements:
/// - Minimum 43 characters, maximum 128 characters
/// - Character set: [A-Za-z0-9-._~] (unreserved URI characters only)
/// - High entropy (256+ bits)
/// 
/// Implementation: Generates 64 random characters (384 bits entropy) from the allowed charset
ClassMethod GenerateVerifier() As %String
{
    // RFC 7636 unreserved characters: [A-Za-z0-9-._~]
    set charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    set charsetLen = $LENGTH(charset)

    // Generate 64 character verifier (384 bits entropy, well above 256-bit minimum)
    set verifier = ""
    new $NAMESPACE
    set $NAMESPACE = "%SYS"

    for i=1:1:64 {
        // Get random byte (0-255)
        set randomByte = $ASCII(##class(%SYSTEM.Encryption).GenCryptRand(1))
        // Map to charset index (1-66)
        set index = (randomByte # charsetLen) + 1
        set verifier = verifier _ $EXTRACT(charset, index)
    }

    return verifier
}

/// Builds the authorization code URL for the given configuration
ClassMethod AuthCodeURL(c As SourceControl.Git.OAuth2.Config, namespace As %String, Output state, Output verifier) As %String
{
    set state = ..GenerateVerifier()    
    set verifier = ..GenerateVerifier()
    set url = c.AuthCodeURL(state, verifier)
    return url
}

ClassMethod GetURLsFromRemote(remote As %String, Output authCodeURL, Output tokenURL) As %Boolean
{
    if remote [ "github.com/" {
        set authCodeURL = "https://github.com/login/oauth/authorize"
        set tokenURL = "https://github.com/login/oauth/access_token"
        return 1
    } elseif remote [ "gitlab" {
        set gitlaburl = $Piece(remote, ".com", 1) _ ".com/"
        set authCodeURL = gitlaburl _ "/oauth/authorize"
        set tokenURL = gitlaburl _ "/oauth/token"
        return 1
    } else {
        return 0
    }
}

ClassMethod FixRemoteURL(url As %String) As %String
{
    /// OAuth Https authentication requires connecting as api
    if ($extract(url,1,5) = "https") {
        if (url [ "@") {
            return url
        } else {
            set url = "https://api@"_$piece(url,"https://",2)
        }
    }
    return url
}

ClassMethod GetToken() As %String
{
    return ##class(SourceControl.Git.Util.CredentialManager).GetAccessToken($username, .err, .code)
}

/// Base64URLEncode converts data to base64url format (RFC 4648 Section 5)
/// Base64url is like standard base64 but URL-safe:
/// - Replace + with -
/// - Replace / with _
/// - Remove padding (=)
/// Used for PKCE code_challenge encoding per RFC 7636
ClassMethod Base64URLEncode(data As %String) As %String
{
    // Convert to standard base64
    set base64 = $SYSTEM.Encryption.Base64Encode(data)

    // Convert to base64url: replace +/= with -_
    set base64url = $REPLACE(base64, "+", "-")
    set base64url = $REPLACE(base64url, "/", "_")

    // Remove padding
    set base64url = $REPLACE(base64url, "=", "")

    return base64url
}

ClassMethod DeleteOAuthConfig(username As %String) As %Status
{
    set sc = $$$OK
    set error = ""
    set code = ""

    // Delete access token
    // Check if token exists first
    set token = ##class(SourceControl.Git.Util.CredentialManager).GetAccessToken(username, .error, .code)
    if error '= "" {
        return $$$ERROR($$$GeneralError,$$$FormatText("Failed to get access token with error: %1; code: %2'",error,code))
    }
    if token '= "" {
        do ##class(SourceControl.Git.Util.CredentialManager).DeleteAccessToken(username, .error, .code)
        if error '= "" {
            return $$$ERROR($$$GeneralError,$$$FormatText("Failed to delete access token with error: %1; code: %2'",error,code))
        }
    }

    // Clear refresh token
    do ##class(SourceControl.Git.Util.CredentialManager).SetRefreshToken(username, "", .error, .code)
    if error '= "" {
       return $$$ERROR($$$GeneralError,$$$FormatText("Failed to clear refresh token with error: %1; code: %2'",error,code))
    }

    // Clear client ID; secret
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(username, "clientid", "", .error, .code)
    if error '= "" {
       return $$$ERROR($$$GeneralError,$$$FormatText("Failed to clear clientid with error: %1; code: %2'",error,code))
    }
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(username, "clientsecret", "", .error, .code)
    if error '= "" {
       return $$$ERROR($$$GeneralError,$$$FormatText("Failed to clear clientsecret with error: %1; code: %2'",error,code))
    }
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(username, "state", "", .error, .code)
    if error '= "" {
       return $$$ERROR($$$GeneralError,$$$FormatText("Failed to clear state with error: %1; code: %2'",error,code))
    }
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(username, "verifier", "", .error, .code)
    if error '= "" {
       return $$$ERROR($$$GeneralError,$$$FormatText("Failed to clear verifier with error: %1; code: %2'",error,code))
    }

    // Delete persistent config object
    if ##class(SourceControl.Git.OAuth2.Config).%ExistsId(username) {
        set sc = ##class(SourceControl.Git.OAuth2.Config).%DeleteId(username)
    }
    return sc
}

}
