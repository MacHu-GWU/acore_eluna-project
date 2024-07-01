--[[
我们定义一个 record 就是结构体数据. 里面有很多 key, value. 这里所有的 key 都是 string,
并且这里有且只有一个 key 是 id. 这个 id 的值可以是 integer 也可以是 string.

我们这个库提供了一组函数, 便于我们能在许多 record 的集合中找到我们想要的 record.
--]]
local record_lookup_utils = {}

---@alias Record table<string, any>

--[[
在定义原始的 record 时, 通常是以列表的形式给出, 这样可以让我们精细化控制它们的顺序.
而在进行映射的时, 我们需要一个 id -> record 的字典. 这个函数可以将列表转化成字典
--]]
---@param recordList Record[]: record 的列表
---@param idKey string: record 的 id 在哪个 key 下面
---@return table<string|number, Record>: id -> record 的字典
function record_lookup_utils.MakeRecordDict(
    recordList,
    idKey
)
    if idKey == nil then idKey = "id" end
    local recordDict = {}
    for _, record in ipairs(recordList) do
        recordDict[record[idKey]] = record
    end
    return recordDict
end

--[[
在所有的 record 中筛选出所有符合 record.key == value 的 record 列表.
这类似于 ``SELECT * FROM records WHERE records.key = value``.
--]]
---@param recordList Record[]: 所有 record 的列表
---@param idKey string: record 的 id 在哪个 key 下面
---@return Record[]: 满足条件的 record 的列表
function record_lookup_utils.FilterByKeyValue(
    recordList,
    key,
    value
)
    --print("----- Start: record_lookup_utils.FindAllByKeyValue(...) ------") -- for debug only
    --print(string.format("  recordList = %s", recordMapping)) -- for debug only
    --print(string.format("  key = %s", key)) -- for debug only
    --print(string.format("  value = %s", value)) -- for debug only
    local filteredRecordList = {}
    -- 注: 这里必须用 ipairs, 确保顺序和定义的顺序一致
    for _, record in ipairs(recordList) do
        if record[key] == value then
            table.insert(filteredRecordList, record)
        end
    end
    --print("----- End: record_lookup_utils.FindAllByKeyValue(...) ------") -- for debug only
    return filteredRecordList
end

return record_lookup_utils
