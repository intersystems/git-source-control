Class %zpkg.isc.sc.git.Defaults
{

ClassMethod GetDefaults() As %Library.DynamicObject [ NotInheritable, Private ]
{
    set defaults = {}
    set storage = "^%SYS(""SourceControl"",""Git"",""defaults"")"
    $$$AddAllRoleTemporary

    set key = $order(@storage@(""))
    while key '= "" {
        do defaults.%Set(key, $get(@storage@(key)))
        set key = $order(@storage@(key))
    }
    return defaults
}

ClassMethod GetDefaultSettings(ByRef defaults As %Library.DynamicObject) As %Status
{
    try {
        set defaults = ..GetDefaults()
    } catch e {
        return e.AsStatus()
    }
    return $$$OK
}

ClassMethod SetDefaults(defaults As %Library.DynamicObject) As %Status [ NotInheritable, Private ]
{
    
    $$$AddAllRoleTemporary
    set storage = "^%SYS(""SourceControl"",""Git"",""defaults"")"
    k @storage
    set iterator = defaults.%GetIterator()

    while iterator.%GetNext(.key, .value) {
        set @storage@(key) = value
    }

    return $$$OK
}

ClassMethod SetDefaultSettings(defaults As %Library.DynamicObject) As %Status [ NotInheritable ]
{

    set newDefaults = {}

    set iterator = defaults.%GetIterator()

    while iterator.%GetNext(.key, .value) {
        do newDefaults.%Set(key, value)
    }

    try {
        do ..SetDefaults(newDefaults)
    } catch e {
        return e.AsStatus()
    }
    return $$$OK
}

}
