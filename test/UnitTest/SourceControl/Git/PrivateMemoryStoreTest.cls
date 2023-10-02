Import SourceControl.Git.Util

Class test.UnitTest.SourceControl.Git.Util.PrivateMemoryStoreTest Extends %UnitTest.TestCase
{

Method TestInsert()
{
        set pvtMemStore = ##class(PrivateMemoryStore).%New(16)
        set keys = $lb("a", "b", "c")
        set values = $lb("123456", "789101112", "131415161718")
        set n = $ListLength(keys)
        for i=1:1:n {
            Set key = $List(keys,i)
            Set value = $List(values,i)
            
            do pvtMemStore.Store(key, value)
        }
        for i=1:1:n {
            Set key = $List(keys,i)
            Set expectedValue = $List(values,i)
            
            do $$$AssertEquals(pvtMemStore.Retrieve(key), expectedValue)
        }
}

}
