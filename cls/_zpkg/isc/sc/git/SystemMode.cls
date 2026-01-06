Class %zpkg.isc.sc.git.SystemMode
{

ClassMethod SetEnvironment(environment As %String) As %Status [ NotInheritable, Private ]
{
    $$$AddAllRoleTemporary
    do $SYSTEM.Version.SystemMode(environment)
    new $namespace
    set $namespace = "%SYS"
    set obj = ##class(Config.Startup).Open()
    set obj.SystemMode = environment
    return obj.%Save()
}

ClassMethod SetSystemMode(environment As %String) As %Status [ NotInheritable ]
{
    try {
        do ..SetEnvironment(environment)
    } catch e {
        return e.AsStatus()
    }
    return $$$OK
}

}
