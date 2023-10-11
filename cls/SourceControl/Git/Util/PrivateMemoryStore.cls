/// Key-value store where values are stored in private memory (for high security).
Class SourceControl.Git.Util.PrivateMemoryStore Extends %RegisteredObject
{

Property buffer [ Internal, Private ];

Property map [ Internal, MultiDimensional, Private ];

Property offset [ InitialExpression = 0, Internal, Private ];

Property size [ Internal, Private ];

Parameter defaultSize = 128;

Method %OnNew(size as %Integer) As %Status [ Private, ServerOnly = 1 ]
{
        if $DATA(size) && $ISVALIDNUM(size) && (size >= 0) {
            set i%size = size
        } else {
            set i%size = ..#defaultSize
        }
        
        set i%buffer = $zu(106,1,i%size)
        return $$$OK
}

Method Store(key, value)
{
    if key = "" {
        // TODO: throw a better exception
        throw ##class(%Exception.General).%New("INVALID_KEY_EXCEPTION","999",, "Invalid key `""""`")
    }
    set length = $length(value)
    // this will clear it if it exists
    do ..Clear(key)
    set requiredSize = length + i%offset
    if (requiredSize > i%size) {
        // TODO: there is definitely a better way to find the appropriate next size
        // using log_2() but won't do that right now

        if i%size=0 {
            set newSize = i%defaultSize
        } else {
            set newSize = i%size*2
        }
        
        while requiredSize > newSize {
            set newSize = newSize*2
        }
        set newBuffer = $zu(106,1,newSize)

        // move values from buffer to newBuffer
        do ..compactBuffer(newBuffer, .newMap, .newOffset)

        // clear current buffer and deallocate
        do ..deallocateBuffer()

        // set to new values
        set i%buffer = newBuffer
        set i%size = newSize
        set i%offset = newOffset
        merge i%map = newMap
    }
    // add mapping for the key
    set i%map(key) = $lb(i%offset,length)
    set i%offset = ..insertIntoMemoryStore(value, i%buffer, i%offset)
}

Method Retrieve(key) As %RawString
{
        return:('..KeyExists(key)) ""

        set $listbuild(offset,length) = i%map(key)
        return $view(i%buffer+offset,-3,-length)
}

Method Clear(key)
{
        quit:('..KeyExists(key))

        kill i%map(key)

        do ..compactBuffer(i%buffer, .newMap, .newOffset)
        // update the map and offset
        kill i%map
        merge i%map = newMap
        set i%offset = newOffset
}

Method %OnClose() As %Status [ Private, ServerOnly = 1 ]
{
    do ..deallocateBuffer()
}

Method KeyExists(key) As %Boolean
{
    if key = "" {
        return 0
    }
    return '($Get(i%map(key)) = "")
}

// PRIVATE METHODS ====>

// Writes to Buffer and returns new offset

Method insertIntoMemoryStore(value, buffer, offset As %Integer) As %Integer [ Private ]
{
    set length = $length(value)
    view buffer+offset:-3:-length:value
    return offset + length
}

Method clearBuffer() [ Private ]
{
    // nulls out buffer
    FOR i = 1:1:i%size {
        view i%buffer+i:-3:-1:0
    }
}

// iterate through ..map and move data from ..buffer to buffer

Method compactBuffer(buffer, Output newMap, Output newOffset) [ Private ]
{
    // pointer to the next place to insert into the buffer
    set newOffset = 0
    kill newMap

    do ..getInverseMap(.inverseMap)
    // iterate through the offsets in ascending order
    set curOffset = ""
    for {
        set curOffset = $order(inverseMap(curOffset))
        quit:(curOffset = "")
        
        set key = inverseMap(curOffset)
        set value = ..Retrieve(key)
        set newMap(key) = $lb(newOffset, $length(value))
        set newOffset = ..insertIntoMemoryStore(value, buffer, newOffset)
    }
}

Method deallocateBuffer() [ Private ]
{
    do ..clearBuffer()
    set i%size = 0
    kill i%map
    do $zu(106,0,i%buffer)
}

// using this method to iterate by sorted offset

// inverseMap is of array type

Method getInverseMap(Output inverseMap) [ Private ]
{
    kill inverseMap
    set iterKey = ""
    for {
        set iterKey = $order(i%map(iterKey))
        quit:(iterKey = "")

        set list = i%map(iterKey)
        set $listbuild(offset,) = list
        
        set inverseMap(offset) = iterKey
    }
}

// util method to print ..map

Method printMap()
{
    set iterKey = ""
    w !
    for {
        set iterKey = $order(i%map(iterKey))
        quit:(iterKey = "")

        w iterKey, ": ", $LISTTOSTRING(i%map(iterKey)), !
    }
}

}
