Class %zpkg.isc.sc.git.Favorites
{
    ClassMethod ConfigureFavoriteNamespaces(username As %String, newNamespaces As %Library.DynamicObject)
{
    // Convert to $listbuild
    set namespaces = $lb("")
    for i=0:1:newNamespaces.%Size() {
        set namespaces = namespaces_$lb(newNamespaces.%Get(i))
    }
    // Call the private method
    try {
        do ..SetFavs(username, namespaces)
    } catch e {
        return e.AsStatus()
    }
    return $$$OK    
}

ClassMethod GetFavoriteNamespaces(ByRef favNamespaces As %DynamicArray, ByRef nonFavNamespaces As %DynamicArray)
{
    try {
        set namespaces = ..GetFavs()
        set favNamespaces = namespaces.%Get("Favorites")
        set nonFavNamespaces = namespaces.%Get("NonFavorites")
    } catch e {
        return e.AsStatus()
    }
    return $$$OK
}

ClassMethod GetFavs() As %Library.DynamicObject [Private] {
    $$$AddAllRoleTemporary
    set allNamespaces = ##class(SourceControl.Git.Utils).GetContexts(1)

    set favNamespaces = []
    set nonFavNamespaces = []

    set username = $USERNAME
    set pagePrefix = "Git:"    
    &sql(DECLARE FavCursor CURSOR FOR SELECT Page into :page from %SYS_Portal.Users where username = :username and page %STARTSWITH :pagePrefix)

    for i=0:1:(allNamespaces.%Size() - 1) {
        set namespace = allNamespaces.%Get(i)
        set foundFlag = 0
        &sql(OPEN FavCursor)
        throw:SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
        &sql(FETCH FavCursor)
        while (SQLCODE = 0) {
            set pageValue = "Git: "_namespace 
            if (page = pageValue) {
                do favNamespaces.%Push(namespace)
                set foundFlag = 1
            }
            &sql(FETCH FavCursor)
        }
        &sql(CLOSE FavCursor)

        if ('foundFlag) {
            do nonFavNamespaces.%Push(namespace)
        }
    }
    return {"Favorites": (favNamespaces), "NonFavorites": (nonFavNamespaces)}
}

ClassMethod SetFavs(username As %String, namespaces As %List) [Private] {
    $$$AddAllRoleTemporary
    &sql(DELETE FROM %SYS_Portal.Users WHERE Username = :username AND Page LIKE '%Git%')

    for i=1:1:$listlength(namespaces) {
        set namespace = $listget(namespaces, i)
        if (namespace '= "") {
            set installNamespace = namespace
            
            // Insert Git link
            set caption = "Git: " _ installNamespace
            set link = "/isc/studio/usertemplates/gitsourcecontrol/webuidriver.csp/" _ installNamespace _ "/"
            &sql(INSERT OR UPDATE INTO %SYS_Portal.Users (Username, Page, Data) VALUES (:username, :caption, :link))
            
            // Insert Git Pull link
            set caption = "Git Pull: " _ installNamespace
            set link = "/isc/studio/usertemplates/gitsourcecontrol/pull.csp?$NAMESPACE=" _ installNamespace
            &sql(INSERT OR UPDATE INTO %SYS_Portal.Users (Username, Page, Data) VALUES (:username, :caption, :link))
        }
    }
}
}