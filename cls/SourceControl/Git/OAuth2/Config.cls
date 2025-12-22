Class SourceControl.Git.OAuth2.Config Extends %Persistent
{

/// Name is the identifier for this configuration
Property Name As %String(MAXLEN = 127);

/// ClientID is the OAuth Application ID. Stored in private memory store only accessible by user
Property ClientID As %String(MAXLEN = "") [ Transient ];

/// ClientSecret is the OAuth Application secret. Stored in private memory store only accessible by user
Property ClientSecret As %String(MAXLEN = "") [ Transient ];

/// Endpoint contains the resource server's token endpoint
Property Endpoint As Endpoint;

/// RedirectURL is the URL to redirect the auth token
/// to after authenticating with the resource owner
Property RedirectURL As %String(MAXLEN = "");

/// State is the CSRF protection token for OAuth2 flow (ephemeral, not persisted)
Property State As %String [ Transient ];

/// Verifier is the PKCE code verifier (ephemeral, not persisted)
Property Verifier As %String [ Transient ];

/// Scopes specifies the list of scopes we are requesting access to
Property Scopes As %List;

Property Username As %String;

/// DirectToken indicates if using a direct authentication token instead of OAuth2 flow
Property DirectToken As %String;

/// AccessTokenExpiry stores the timestamp when the access token expires
Property AccessTokenExpiry As %TimeStamp;

/// ConnectionTimeout in seconds for establishing TCP connection (default: 10 seconds)
Property ConnectionTimeout As %Integer [ InitialExpression = 10 ];

/// ResponseTimeout in seconds for receiving full HTTP response (default: 30 seconds)
Property ResponseTimeout As %Integer [ InitialExpression = 30 ];

Index Username On Username [ IdKey, Unique ];

Method ClientIDSet(InputValue As %String) As %Status
{
    set code = "", error = ""
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(..Username,"clientid",InputValue, .error, .code)
    if (code '= 1) || (error '= "") {
        return $$$ERROR($$$GeneralError,"Set failed with following error: "_error)
    }
    return $$$OK
}

Method ClientIDGet() As %String
{
    return ##class(SourceControl.Git.Util.CredentialManager).GetKeyPair(..Username,"clientid", .error, .code)
}

Method ClientSecretSet(InputValue As %String) As %Status
{
    set code = "", error = ""
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(..Username,"clientsecret",InputValue, .error, .code)
    if (code '= 1) || (error '= "") {
        return $$$ERROR($$$GeneralError,"Set failed with following error: "_error)
    }
    return $$$OK
}

Method ClientSecretGet() As %String
{
    return ##class(SourceControl.Git.Util.CredentialManager).GetKeyPair(..Username,"clientsecret", .error, .code)
}

ClassMethod GetConfig(username As %String) As SourceControl.Git.OAuth2.Config
{
    set config = ##class(SourceControl.Git.OAuth2.Config).%OpenId(username)

    return config
}

// TODO: We will need a authStyleCache when we use autodetect for Endpoint.AuthStyle in the future

Method %OnNew(configName As %String, clientID As %String, clientSecret As %String, authEndpoint As %String, tokenEndpoint As %String, redirectURL As %String, scopes As %List = "") As %Status
{
    set ..Name = configName
    set ..Username = $username
    set ..ClientID = clientID
    set ..ClientSecret = clientSecret
    set ..Endpoint = ##class(Endpoint).%New()
    set ..Endpoint.AuthURL = authEndpoint
    set ..Endpoint.TokenURL = tokenEndpoint
    set ..RedirectURL = redirectURL
    set ..DirectToken = 0


    if ('scopes) {
        set scopes = $lb("repo")
    }
    set ..Scopes = scopes

    return $$$OK
}

Method AuthCodeURL(state As %String, verifier As %String) As %String
{
    set params("response_type") = "code"
    set params("client_id") = ..ClientID
    set:(..RedirectURL '= "") params("redirect_uri") = ..RedirectURL
    set:(state '= "") params("state") = state
    set:($LISTLENGTH(..Scopes) > 0) params("scope") = $LISTTOSTRING(..Scopes," ")
    if verifier {
        set code = ##class(%SYSTEM.Encryption).SHAHash(256, verifier)
        set params("code_challenge_method") = "S256"
        set params("code_challenge") = code
    }
    
    return ..GetURLWithParams(..Endpoint.AuthURL, .params)
}

Method Exchange(authCode As %String, verifier As %String, Output sc As %Status) As %String
{
    do ##class(%Net.URLParser).Decompose(..Endpoint.TokenURL, .urlComponents)

    set request = ##class(%Net.HttpRequest).%New()
    set request.Server = urlComponents("host")
    set request.Https = (urlComponents("scheme")="https")

    // Apply timeout configuration (Issue #10)
    set request.Timeout = ..ResponseTimeout
    set request.OpenTimeout = ..ConnectionTimeout

    do request.SetParam("grant_type", "authorization_code")
    do request.SetParam("code", authCode)
    do request.SetParam("code_verifier", verifier)
    do:(..ClientID '= "") request.SetParam("client_id", ..ClientID)
    do:(..ClientSecret '= "") request.SetParam("client_secret", ..ClientSecret)
    // we don't need the redirect_uri parameter because we will be consuming the token here

    do request.SetHeader("Accept", "application/json")

    do ..CreateSSLConfigIfNonExistent("GitExtensionForIris")

    set request.SSLConfiguration = "GitExtensionForIris"

    // OAuth2 spec (RFC 6749 Section 4.1.3) requires POST for token endpoint
    set sc = request.Post(urlComponents("path"))
    if sc '= $$$OK {
        // Network-level error (connection failed, timeout, DNS failure, etc.)
        set sc = $$$ERROR($$$GeneralError, "Network error: "_$SYSTEM.Status.GetErrorText(sc))
        return ""
    }

    // Check HTTP status code (Issue #9)
    set httpStatus = request.HttpResponse.StatusCode
    if httpStatus '= 200 {
        // HTTP error - parse error response if available
        set errorMsg = "HTTP "_httpStatus

        try {
            set errorObj = {}.%FromJSON(request.HttpResponse.Data)
            if errorObj.%IsDefined("error") {
                set errorMsg = errorMsg_": "_errorObj.%Get("error")
                if errorObj.%IsDefined("error_description") {
                    set errorMsg = errorMsg_" - "_errorObj.%Get("error_description")
                }
            } else {
                set errorMsg = errorMsg_": "_request.HttpResponse.ReasonPhrase
            }
        } catch {
            // If error response isn't JSON, use reason phrase
            set errorMsg = errorMsg_": "_request.HttpResponse.ReasonPhrase
        }

        // Add specific guidance based on status code
        if httpStatus = 400 {
            set errorMsg = errorMsg_" (Invalid authorization code or parameters)"
        } elseif httpStatus = 401 {
            set errorMsg = errorMsg_" (Invalid client credentials - check client_id and client_secret)"
        } elseif httpStatus = 403 {
            set errorMsg = errorMsg_" (Client not authorized for this resource)"
        } elseif httpStatus = 404 {
            set errorMsg = errorMsg_" (Token endpoint not found - check endpoint URL)"
        } elseif httpStatus = 429 {
            set errorMsg = errorMsg_" (Rate limited - too many requests. Please wait before retrying)"
        } elseif (httpStatus >= 500) && (httpStatus < 600) {
            set errorMsg = errorMsg_" (Provider service error - please try again later)"
        }

        set sc = $$$ERROR($$$GeneralError, errorMsg)
        return ""
    }

    try {
        set obj = {}.%FromJSON(request.HttpResponse.Data)
    } catch ex {
        set sc = ex.AsStatus()
        return "" 
    }
    
    if obj.%IsDefined("access_token") && (obj.%GetTypeOf("access_token") = "string") {
        set accessToken = obj.%Get("access_token")

        // Parse and store token expiration (Issue #5)
        if obj.%IsDefined("expires_in") {
            set expiresIn = obj.%Get("expires_in")

            // Calculate expiry: current time + expires_in seconds
            // $HOROLOG is in format "date,seconds" where seconds is time since midnight
            set currentHorolog = $HOROLOG
            set currentDate = $PIECE(currentHorolog, ",", 1)
            set currentSeconds = $PIECE(currentHorolog, ",", 2)

            // Add expires_in seconds and handle day rollover
            set expirySeconds = currentSeconds + expiresIn
            set daysToAdd = expirySeconds \ 86400  // Integer division (seconds per day)
            set expirySeconds = expirySeconds # 86400  // Modulo (remaining seconds)
            set expiryDate = currentDate + daysToAdd

            // Reconstruct $HOROLOG format and convert to ODBC timestamp
            set expiryHorolog = expiryDate _ "," _ expirySeconds
            set ..AccessTokenExpiry = $ZDATETIME(expiryHorolog, 3)
        } else {
            // If no expires_in, set to empty (token doesn't expire or unknown)
            set ..AccessTokenExpiry = ""
        }

        // Save config to persist expiry timestamp
        set saveSc = ..%Save()
        if saveSc '= $$$OK {
            // Log save error but don't fail token exchange
            // TODO: Add logging when SourceControl.Git.Util.Log is available
        }

        return accessToken
    } else {
        set sc = $$$ERROR($$$GeneralError,"Unable to read access_token from response")
        return ""
    }
}

/// IsTokenExpired checks if the access token has expired
/// Returns 1 (true) if expired or no expiry set, 0 (false) if still valid
Method IsTokenExpired() As %Boolean
{
    // If no expiry timestamp set, consider expired
    if ..AccessTokenExpiry = "" {
        return 1
    }

    // Compare current time with expiry timestamp
    // Both are in ODBC format (YYYY-MM-DD HH:MM:SS) which is string-comparable
    set currentTime = $ZDATETIME($HOROLOG, 3)
    return currentTime >= ..AccessTokenExpiry
}

ClassMethod CreateSSLConfigIfNonExistent(name As %String)
{
    do ##class(%zpkg.isc.sc.git.SSLConfig).CreateSSLConfigIfNonExistent(name)
}

ClassMethod GetURLWithParams(url As %String, ByRef params As %String) As %String
{
    if $find(url, "?") {
        set url = url_"&"
    } else {
        set url = url_"?"
    }
    
    set curParamKey = ""
    for {
        set isFirstIter = (curParamKey = "")
        set curParamKey = $order(params(curParamKey), 1, curParamValue)
        
        set isLastIter = (curParamKey = "")
        set:'(isFirstIter || isLastIter) url = url_"&"

        quit:(isLastIter)

        set url = url_$$$URLENCODE(curParamKey)_"="_$$$URLENCODE(curParamValue)
    }
    return url
}

Storage Default
{
<Data name="ConfigDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Endpoint</Value>
</Value>
<Value name="4">
<Value>RedirectURL</Value>
</Value>
<Value name="5">
<Value>Scopes</Value>
</Value>
<Value name="6">
<Value>DirectToken</Value>
</Value>
<Value name="7">
<Value>AccessTokenExpiry</Value>
</Value>
<Value name="8">
<Value>ConnectionTimeout</Value>
</Value>
<Value name="9">
<Value>ResponseTimeout</Value>
</Value>
</Data>
<DataLocation>^SourceControl.Git.O7826.ConfigD</DataLocation>
<DefaultData>ConfigDefaultData</DefaultData>
<IdLocation>^SourceControl.Git.O7826.ConfigD</IdLocation>
<IndexLocation>^SourceControl.Git.O7826.ConfigI</IndexLocation>
<StreamLocation>^SourceControl.Git.O7826.ConfigS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
