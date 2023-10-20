Class SourceControl.Git.OAuth2.Config Extends %RegisteredObject
{

/// Name is the identifier for this configuration
Property Name As %String(MAXLEN = 127);

/// ClientID is the OAuth Application ID
Property ClientID As %String(MAXLEN = "");

/// ClientSecret is the OAuth Application secret
Property ClientSecret As %String(MAXLEN = "");

/// Endpoint contains the resource server's token endpoint
Property Endpoint As Endpoint;

/// RedirectURL is the URL to redirect the auth token
/// to after authenticating with the resource owner
Property RedirectURL As %String(MAXLEN = "");

/// Scopes specifies the list of scopes we are requesting access to
Property Scopes;

Index NameID On Name [ IdKey ];

// TODO: We will need a authStyleCache when we use autodetect for Endpoint.AuthStyle in the future

Method %OnNew(configName As %String, clientID As %String, clientSecret As %String, authEndpoint As %String, tokenEndpoint As %String, redirectURL As %String, scopes As %String) As %Status
{
    set ..Name = configName
    set ..ClientID = clientID
    set ..ClientSecret = clientSecret
    set ..Endpoint = ##class(Endpoint).%New()
    set ..Endpoint.AuthURL = authEndpoint
    set ..Endpoint.TokenURL = tokenEndpoint
    set ..RedirectURL = redirectURL
    set ..Scopes = scopes

    return $$$OK
}

Method AuthCodeURL(state As %String, verifier As %String) As %String
{
    #; new $NAMESPACE
    #; set $NAMESPACE = "%SYS"

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
    do request.SetParam("grant_type", "authorization_code")
    do request.SetParam("code", authCode)
    do request.SetParam("code_verifier", verifier)
    do:(..ClientID '= "") request.SetParam("client_id", ..ClientID)
    do:(..ClientSecret '= "") request.SetParam("client_secret", ..ClientSecret)
    // we don't need the redirect_uri parameter because we will be consuming the token here

    // TODO: also add support to put client creds in header instead of params
    // either is allowed, will have to try both to see which succeeds
    // this is when we will need the `AuthStyle` parameter in the endpoint
    do request.SetHeader("Accept", "application/json")

    set request.SSLConfiguration = "GitExtensionForIris"
    set sc = request.Get(urlComponents("path"))
    if sc '= $$$OK {
        // something went wrong
        return ""
    }

    try {
        set obj = {}.%FromJSON(request.HttpResponse.Data)
    } catch ex {
        set sc = ex.AsStatus()
        return "" 
    }
    
    if obj.%IsDefined("access_token") && (obj.%GetTypeOf("access_token") = "string") {
       return obj.%Get("access_token")
    } else {
        set sc = $$$ERROR($$$GeneralError,"Unable to read access_token from response")
        return ""
    }
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
<Value>ClientID</Value>
</Value>
<Value name="3">
<Value>ClientSecret</Value>
</Value>
<Value name="4">
<Value>Endpoint</Value>
</Value>
<Value name="5">
<Value>RedirectURL</Value>
</Value>
<Value name="6">
<Value>Scopes</Value>
</Value>
</Data>
<Data name="ConfigState">
<Value name="1">
<Value>Name</Value>
</Value>
<Value name="2">
<Value>ClientID</Value>
</Value>
<Value name="3">
<Value>ClientSecret</Value>
</Value>
<Value name="4">
<Value>Endpoint</Value>
</Value>
<Value name="5">
<Value>RedirectURL</Value>
</Value>
<Value name="6">
<Value>Scopes</Value>
</Value>
</Data>
<DataLocation>^SourceControl.Git.O7826.ConfigD</DataLocation>
<DefaultData>ConfigDefaultData</DefaultData>
<IdLocation>^SourceControl.Git.O7826.ConfigD</IdLocation>
<IndexLocation>^SourceControl.Git.O7826.ConfigI</IndexLocation>
<State>ConfigState</State>
<StreamLocation>^SourceControl.Git.O7826.ConfigS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
