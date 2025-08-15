Class UnitTest.SourceControl.Git.PrivateMemoryStore Extends %UnitTest.TestCase
{

Method TestInsert()
{
    set pvtMemStore = ##class(SourceControl.Git.Util.PrivateMemoryStore).%New(16)
    set keys = $lb("a", "b", "c")
    set values = $lb("123456", "789101112", "131415161718")
    set n = $ListLength(keys)
    do ..InsertToMemoryStore(pvtMemStore, keys, values)

    for i=1:1:n {
        Set key = $List(keys,i)
        Set expectedValue = $List(values,i)
        
        do $$$AssertEquals(pvtMemStore.Retrieve(key), expectedValue)
    }
}

ClassMethod InsertToMemoryStore(store, keys, ByRef values)
{
    set n = $ListLength(keys)
    for i=1:1:n {
        Set key = $List(keys,i)
        Set value = $List(values,i)
        do store.Store(key, value)
    }
}

Method TestDelete()
{
    set pvtMemStore = ##class(SourceControl.Git.Util.PrivateMemoryStore).%New(16)
    set keys = $lb("a", "b", "c")
    set values = $lb("123456", "789101112", "131415161718")
    do ..InsertToMemoryStore(pvtMemStore, keys, values)
    set n = $ListLength(keys)
 
    for i=1:1:n-1 {
        do pvtMemStore.Clear($List(keys,i))
    }
 
    for i=1:1:n-1 {
        do $$$AssertEquals(pvtMemStore.KeyExists($List(keys,i)), 0)
    }
 
    do $$$AssertEquals(pvtMemStore.Retrieve($List(keys,n)), $List(values,n))
}

}
