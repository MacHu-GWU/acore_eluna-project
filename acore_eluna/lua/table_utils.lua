--[[
这个库提供了一些对 table 数据结构的增强.
--]]

local table_utils = {}

---计算一个类似 Python dict 的 table 的长度
---@param dict table
---@return number
function table_utils.GetDictLength(dict)
    local count = 0
    for _ in pairs(dict) do
        count = count + 1
    end
    return count
end

return table_utils
