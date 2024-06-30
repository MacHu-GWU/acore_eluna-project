local table_utils = require("table_utils")

local function TestCountPairs()
    local dict = { a = 1, b = 2, c = 3 }
    assert(table_utils.GetDictLength(dict) == 3)
end

TestCountPairs()