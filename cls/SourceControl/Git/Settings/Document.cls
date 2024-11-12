/// Custom studio document type for Embedded Git settings that are controlled by a file
Class SourceControl.Git.Settings.Document Extends %Studio.AbstractDocument
{

Projection RegisterExtension As %Projection.StudioDocument(DocumentExtension = "GSC", DocumentNew = 0, DocumentType = "json");

Parameter INTERNALNAME = "embedded-git-config.GSC";

Parameter EXTERNALNAME = "embedded-git-config.json";

/// Return 1 if the routine 'name' exists and 0 if it does not.
ClassMethod Exists(name As %String) As %Boolean
{
    return (name = ..#INTERNALNAME)
}

/// Load the routine in Name into the stream Code
Method Load() As %Status
{
    set sc = $$$OK
    try {
        set stream = ..GetCurrentStream()
        $$$ThrowOnError(..Code.CopyFromAndSave(stream))
        $$$ThrowOnError(..Code.Rewind())
        do ..UpdateHash(stream)
    } catch err {
        set sc = err.AsStatus()
    }
    return sc
}

Method GetCurrentStream() As %Stream.Object
{
    set settings = ##class(SourceControl.Git.Settings).%New()
    set dynObj = settings.ToDynamicObject()
    set formatter = ##class(%JSON.Formatter).%New()
    $$$ThrowOnError(formatter.FormatToStream(dynObj, .stream))
    return stream
}

/// Save the routine stored in Code
Method Save() As %Status
{
    set sc = $$$OK
    try {
        try {
            set settingsJSON = ##class(%DynamicObject).%FromJSON(..Code)
        } catch err {
            $$$ThrowStatus($$$ERROR($$$GeneralError, "Invalid JSON"))
        }
        set settings = ##class(SourceControl.Git.Settings).%New()
        do settings.ImportDynamicObject(settingsJSON)
        set sc = settings.%Save()
        quit:$$$ISERR(sc)
    } catch err {
        set sc = err.AsStatus()
    }
    return sc
}

ClassMethod ListExecute(ByRef qHandle As %Binary, Directory As %String, Flat As %Boolean, System As %Boolean) As %Status
{
	if $g(Directory)'="" {
        set qHandle="" 
        quit $$$OK
    }
	set qHandle = $listbuild(1,"")
	quit $$$OK
}

ClassMethod ListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = ListExecute ]
{
	set Row="", AtEnd=0
	set rownum = $lg(qHandle,1)
	if rownum'=1 {
        set AtEnd = 1 
    } else {
        set Row = $listbuild(..#INTERNALNAME,$zts-5,0,"")
        set $list(qHandle,1) = 2
    }
	quit $$$OK
}

ClassMethod ListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = ListExecute ]
{
	set qHandle = ""
	quit $$$OK
}

Method UpdateHash(stream)
{
	set stream = $Get(stream,..GetCurrentStream())
	set hash = $System.Encryption.SHA1HashStream(stream)
    if $get(@##class(SourceControl.Git.Utils).#Storage@("settings","Hash")) '= hash {
        set @##class(SourceControl.Git.Utils).#Storage@("settings","Hash") = hash
        set @##class(SourceControl.Git.Utils).#Storage@("settings","TS") = $zdatetime($h,3)
	}
}

/// Return the timestamp of routine 'name' in %TimeStamp format. This is used to determine if the routine has
/// been updated on the server and so needs reloading from Studio. So the format should be $zdatetime($horolog,3),
/// or "" if the routine does not exist.
ClassMethod TimeStamp(name As %String) As %TimeStamp
{
    return $get(@##class(SourceControl.Git.Utils).#Storage@("settings","TS"), $zdatetime($h,3))
}

}
