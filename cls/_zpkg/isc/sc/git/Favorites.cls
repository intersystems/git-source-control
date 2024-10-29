Class %zpkg.isc.sc.git.Favorites Extends %RegisteredObject
{
    ClassMethod ConfigureFavoriteNamespaces(username As %String, newNamespaces As %String)
{
    $$$AddAllRoleTemporary
    // Delete all the GIT favorite links for the user 
    &sql(DELETE FROM %SYS_Portal.Users WHERE Username = :username AND Page LIKE '%Git%')

    set iterator = newNamespaces.%GetIterator()
    while iterator.%GetNext(.key, .value) {
        set installNamespace = value
        
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

ClassMethod GetFavoriteNamespaces(ByRef favNamespaces As %DynamicArray, ByRef nonFavNamespaces As %DynamicArray)
{
    $$$AddAllRoleTemporary
    set allNamespaces = ##class(SourceControl.Git.Utils).GetContexts(1)
    set iterator = allNamespaces.%GetIterator()

    set username = $USERNAME
    set pagePrefix = "Git:"    
    &sql(DECLARE FavCursor CURSOR FOR SELECT Page into :page from %SYS_Portal.Users where username = :username and page %STARTSWITH :pagePrefix)

    while iterator.%GetNext(.key, .value) {
        set foundFlag = 0
        &sql(OPEN FavCursor)
        throw:SQLCODE<0 ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg)
        &sql(FETCH FavCursor)
        while (SQLCODE = 0) {
            set pageValue = "Git: "_value 
            if (page = pageValue) {
                do favNamespaces.%Push(value)
                set foundFlag = 1
            }
            &sql(FETCH FavCursor)
        }
        &sql(CLOSE FavCursor)

        if ('foundFlag) {
            do nonFavNamespaces.%Push(value)
        }
    }
}
}