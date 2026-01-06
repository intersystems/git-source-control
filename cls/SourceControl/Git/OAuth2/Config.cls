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
Property DirectToken As %String [ InitialExpression = 0 ];

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
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(..Username, "clientid", InputValue, .error, .code)
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
    do ##class(SourceControl.Git.Util.CredentialManager).SetKeyPair(..Username, "clientsecret", InputValue, .error, .code)
    if (code '= 1) || (error '= "") {
        return $$$ERROR($$$GeneralError,"Set failed with following error: "_error)
    }
    return $$$OK
}

Method ClientSecretGet() As %String
{
    return ##class(SourceControl.Git.Util.CredentialManager).GetKeyPair(..Username, "clientsecret", .error, .code)
}

ClassMethod GetConfig(username As %String) As SourceControl.Git.OAuth2.Config
{
    set config = ##class(SourceControl.Git.OAuth2.Config).%OpenId(username)

    return config
}

/// TODO: We will need a authStyleCache when we use autodetect for Endpoint.AuthStyle in the future
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
    if verifier '= "" {
        // Generate SHA-256 hash and encode in base64url per RFC 7636
        // SHAHash returns raw bytes, which we need to encode in base64url
        set hashBytes = ##class(%SYSTEM.Encryption).SHAHash(256, verifier)
        set codeChallenge = ##class(SourceControl.Git.OAuth2).Base64URLEncode(hashBytes)

        set params("code_challenge_method") = "S256"
        set params("code_challenge") = codeChallenge
    }

    return ..GetURLWithParams(..Endpoint.AuthURL, .params)
}

Method Exchange(authCode As %String, verifier As %String, Output sc As %Status) As %String
{
    set sc = $$$OK

    // Create and configure token request
    set request = ..CreateTokenRequest(.sc)
    if sc '= $$$OK {
        return ""
    }

    // Set authorization code grant parameters
    do request.SetParam("grant_type", "authorization_code")
    do request.SetParam("code", authCode)
    do request.SetParam("code_verifier", verifier)

    if ..ClientID '= "" {
        do request.SetParam("client_id", ..ClientID)
    }

    if ..ClientSecret '= "" {
        do request.SetParam("client_secret", ..ClientSecret)
    }

    // Execute request and get response
    set obj = ..ExecuteTokenRequest(request, .sc)
    if sc '= $$$OK {
        return ""
    }

    // Extract access token
    if obj.%IsDefined("access_token") && (obj.%GetTypeOf("access_token") = "string") {
        set accessToken = obj.%Get("access_token")

        // Calculate and store token expiration
        if obj.%IsDefined("expires_in") {
            set expiresIn = obj.%Get("expires_in")
            set ..AccessTokenExpiry = ..CalculateTokenExpiry(expiresIn)
        } else {
            set ..AccessTokenExpiry = ""
        }

        // Parse and store refresh_token if present
        if obj.%IsDefined("refresh_token") {
            set refreshToken = obj.%Get("refresh_token")

            // Store refresh token in CredentialManager
            do ##class(SourceControl.Git.Util.CredentialManager).SetRefreshToken(
                ..Username,
                refreshToken,
                .refreshError,
                .refreshCode
            )

            if (refreshCode '= 1) || (refreshError '= "") {
                // Log but don't fail - refresh token is optional
                // TODO: Add logging when available
            }
        }

        // Save config to persist expiry timestamp
        set saveSc = ..%Save()
        if saveSc '= $$$OK {
            // Log save error but don't fail token exchange
            // TODO: Add logging when available
        }

        return accessToken
    } else {
        set sc = $$$ERROR($$$GeneralError,"Unable to read access_token from response")
        return ""
    }
}

/// CreateTokenRequest creates and configures an HTTP request for the token endpoint
/// Returns configured HttpRequest object
Method CreateTokenRequest(Output sc As %Status) As %Net.HttpRequest
{
    set sc = $$$OK

    // Parse token endpoint URL
    do ##class(%Net.URLParser).Decompose(..Endpoint.TokenURL, .urlComponents)

    // Create HTTP request
    set request = ##class(%Net.HttpRequest).%New()
    set request.Server = urlComponents("host")

    if urlComponents("scheme") = "https" {
        set request.Https = 1
    } else {
        set request.Https = 0
    }

    // Apply timeout configuration
    set request.Timeout = ..ResponseTimeout
    set request.OpenTimeout = ..ConnectionTimeout

    do request.SetHeader("Accept", "application/json")

    // Configure SSL
    do ..CreateSSLConfigIfNonExistent("GitExtensionForIris")
    set request.SSLConfiguration = "GitExtensionForIris"

    return request
}

/// ExecuteTokenRequest posts to token endpoint and validates the response
/// Returns parsed JSON object or "" on error
Method ExecuteTokenRequest(request As %Net.HttpRequest, Output sc As %Status) As %DynamicObject
{
    set sc = $$$OK

    // Parse URL to get path
    do ##class(%Net.URLParser).Decompose(..Endpoint.TokenURL, .urlComponents)

    // POST to token endpoint
    set postSc = request.Post(urlComponents("path"))
    if postSc '= $$$OK {
        set sc = $$$ERROR($$$GeneralError, "Network error: "_$SYSTEM.Status.GetErrorText(postSc))
        return ""
    }

    // Check HTTP status
    set httpStatus = request.HttpResponse.StatusCode
    if httpStatus '= 200 {
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
            set errorMsg = errorMsg_": "_request.HttpResponse.ReasonPhrase
        }

        // Add specific guidance based on status code
        if httpStatus = 400 {
            set errorMsg = errorMsg_" (Invalid parameters)"
        } elseif httpStatus = 401 {
            set errorMsg = errorMsg_" (Invalid credentials)"
        } elseif httpStatus = 403 {
            set errorMsg = errorMsg_" (Not authorized)"
        } elseif httpStatus = 404 {
            set errorMsg = errorMsg_" (Token endpoint not found)"
        } elseif httpStatus = 429 {
            set errorMsg = errorMsg_" (Rate limited)"
        } elseif (httpStatus >= 500) && (httpStatus < 600) {
            set errorMsg = errorMsg_" (Server error)"
        }

        set sc = $$$ERROR($$$GeneralError, errorMsg)
        return ""
    }

    // Parse response JSON
    try {
        set contentType = request.HttpResponse.GetHeader("CONTENT-TYPE")

        // Try JSON first (GitHub should return this with Accept: application/json)
        set obj = {}.%FromJSON(request.HttpResponse.Data)
        return obj
    } catch ex {
        // If JSON parsing fails, try URL-encoded format

        // Reset stream position
        do request.HttpResponse.Data.Rewind()
        set responseText = request.HttpResponse.Data.Read()

        // Try parsing as URL-encoded (access_token=xxx&token_type=bearer)
        if responseText [ "access_token=" {
            set obj = {}
            // Parse URL-encoded response
            for i=1:1:$LENGTH(responseText,"&") {
                set pair = $PIECE(responseText,"&",i)
                if pair '= "" {
                    set key = $PIECE(pair,"=",1)
                    set value = $PIECE(pair,"=",2,*)  // Handle values with = in them
                    do obj.%Set(key, value)
                }
            }
            return obj
        }

        set sc = ex.AsStatus()
        return ""
    }
}

/// CalculateTokenExpiry calculates the expiry timestamp from expires_in seconds
/// Returns ODBC timestamp string (YYYY-MM-DD HH:MM:SS)
ClassMethod CalculateTokenExpiry(expiresInSeconds As %Integer) As %TimeStamp
{
    set currentHorolog = $HOROLOG
    set currentDate = $PIECE(currentHorolog, ",", 1)
    set currentSeconds = $PIECE(currentHorolog, ",", 2)

    // Add expires_in seconds and handle day rollover
    set expirySeconds = currentSeconds + expiresInSeconds
    set daysToAdd = expirySeconds \ 86400  // Integer division (seconds per day)
    set expirySeconds = expirySeconds # 86400  // Modulo (remaining seconds)
    set expiryDate = currentDate + daysToAdd

    // Reconstruct $HOROLOG format and convert to ODBC timestamp
    set expiryHorolog = expiryDate _ "," _ expirySeconds
    return $ZDATETIME(expiryHorolog, 3)
}

/// RefreshAccessToken uses the refresh token to obtain a new access token
/// Returns new access token or "" on failure
Method RefreshAccessToken(Output sc As %Status) As %String
{
    set sc = $$$OK

    // Retrieve refresh token from CredentialManager
    set refreshToken = ##class(SourceControl.Git.Util.CredentialManager).GetRefreshToken(
        ..Username,
        .error,
        .code
    )

    // Check if we have a refresh token
    if (refreshToken = "") || (error '= "") {
        set sc = $$$ERROR($$$GeneralError, "No refresh token available: "_error)
        return ""
    }

    // Create and configure token request
    set request = ..CreateTokenRequest(.sc)
    if sc '= $$$OK {
        return ""
    }

    // Set refresh token grant parameters (RFC 6749 Section 6)
    do request.SetParam("grant_type", "refresh_token")
    do request.SetParam("refresh_token", refreshToken)

    if ..ClientID '= "" {
        do request.SetParam("client_id", ..ClientID)
    }

    if ..ClientSecret '= "" {
        do request.SetParam("client_secret", ..ClientSecret)
    }

    // Execute request and get response
    set obj = ..ExecuteTokenRequest(request, .sc)
    if sc '= $$$OK {
        // If refresh token is invalid/expired (400/401), clear it
        set errorText = $SYSTEM.Status.GetErrorText(sc)
        if (errorText [ "HTTP 400") || (errorText [ "HTTP 401") {
            do ##class(SourceControl.Git.Util.CredentialManager).SetRefreshToken(
                ..Username,
                "",
                .clearError,
                .clearCode
            )
        }
        return ""
    }

    // Extract new access token
    if obj.%IsDefined("access_token") {
        set accessToken = obj.%Get("access_token")

        // Calculate and store token expiration
        if obj.%IsDefined("expires_in") {
            set expiresIn = obj.%Get("expires_in")
            set ..AccessTokenExpiry = ..CalculateTokenExpiry(expiresIn)
        }

        // Update refresh token if new one provided (token rotation)
        if obj.%IsDefined("refresh_token") {
            set newRefreshToken = obj.%Get("refresh_token")
            do ##class(SourceControl.Git.Util.CredentialManager).SetRefreshToken(
                ..Username,
                newRefreshToken,
                .refreshError,
                .refreshCode
            )
        }

        // Store new access token
        do ##class(SourceControl.Git.Util.CredentialManager).SetAccessToken(
            ..Username,
            accessToken,
            .tokenError,
            .tokenCode
        )

        if (tokenCode '= 1) || (tokenError '= "") {
            set sc = $$$ERROR($$$GeneralError, "Failed to store refreshed access token: "_tokenError)
            return ""
        }

        // Save updated config (expiry timestamp)
        set saveSc = ..%Save()
        if saveSc '= $$$OK {
            // Log but don't fail
            // TODO: Add logging
        }

        return accessToken
    } else {
        set sc = $$$ERROR($$$GeneralError, "Token refresh response missing access_token")
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
<Value name="10">
<Value>Namespace</Value>
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
