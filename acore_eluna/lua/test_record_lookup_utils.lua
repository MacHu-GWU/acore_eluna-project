local record_lookup_utils = require("record_lookup_utils")
local table_utils = require("table_utils")

local function TestMakeMapping()
    local recordList = {
        { id = 100, name = "Alice" },
        { id = 200, name = "Bob" },
        { id = 300, name = "Cathy" }
    }
    local recordDict = record_lookup_utils.MakeRecordDict(recordList)

    assert(table_utils.GetDictLength(recordDict) == 3)
    assert(recordDict[100].id == 100)
    assert(recordDict[100].name == "Alice")

    record = recordDict[100]
    assert(record.id == 100)
    assert(record.name == "Alice")
end

local function TestFilterByKeyValue()
    local recordList = {
        { id = 100, name = "Alice" },
        { id = 200, name = "Bob" },
        { id = 300, name = "Cathy" }
    }
    local filteredRecordList = record_lookup_utils.FilterByKeyValue(
            recordList,
            "name",
            "Bob"
    )
    assert(#filteredRecordList == 1)
    assert(filteredRecordList[1].id == 200)
    assert(filteredRecordList[1].name == "Bob")
end

TestMakeMapping()
TestFilterByKeyValue()
