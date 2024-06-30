--[[
我们定义一个 data 就是

--]]
local record_lookup_utils = {}

record_lookup_utils.ABC = 100

function record_lookup_utils.FindIdByKeyValue(
    choiceDataMapper,
    choiceDataKey,
    choiceDataValue
)
    --[[
    这个函数的目的是查找第一个 key, value pair 符合条件的 choiceData 的 id.

    类似于 ``SELECT ID FROM table WHERE table.choiceDataKey = choiceDataValue LIMIT 1``.

    :type choiceDataMapper: table
    :param choiceDataMapper: 一个 {id: choiceData} 的字典, 其中 id 是整数.
    :type choiceDataKey: string
    :param choiceDataKey: choiceData 中的 key
    :type choiceDataKey: any
    :param choiceDataValue: choiceData 中的 value

    :return: 符合条件的 choiceData 的 id.
    --]]
    --print("    ----- Start: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
    --print(string.format("      choiceDataMapper = %s", choiceDataMapper)) -- for debug only
    --print(string.format("      choiceDataKey = %s", choiceDataKey)) -- for debug only
    --print(string.format("      choiceDataValue = %s", choiceDataValue)) -- for debug only
    for choiceDataId, choiceData in pairs(choiceDataMapper) do
        if choiceDataKey then
            if choiceData[choiceDataKey] == choiceDataValue then
                --print("    ----- End: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
                return choiceDataId
            end
        else -- 貌似无论如何都不会进入到这段逻辑中
            if choiceData == choiceDataValue then
                --print("    ----- End: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
                return choiceDataId
            end
        end
    end
    --print("    ----- End: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
end

function record_lookup_utils.FindAllByKeyValue(
    choiceDataMapper,
    choiceDataKey,
    choiceDataValue
)
    --[[
    这个函数的目的是查找所有 key, value pair 符合条件的 choiceData 的列表.

    类似于 ``SELECT ID FROM table WHERE talbe.choiceDataKey = choiceDataValue``.

    :type choiceDataMapper: table
    :param choiceDataMapper: 一个 {id: choiceData} 的字典, 其中 ID 是整数.
    :type choiceDataKey: string
    :param choiceDataKey: choiceData 中的 key
    :type choiceDataKey: any
    :param choiceDataValue: choiceData 中的 value

    :return: 符合条件的所有 choiceData 的列表.
    --]]
    print("    ----- Start: CpiMultiVendor.FindAllByKeyValue(...) ------") -- for debug only
    print(string.format("      choiceDataMapper = %s", choiceDataMapper)) -- for debug only
    print(string.format("      choiceDataKey = %s", choiceDataKey)) -- for debug only
    print(string.format("      choiceDataValue = %s", choiceDataValue)) -- for debug only
    local choiceDataList = {}
    -- 注: 这里必须用 ipairs, 确保顺序和定义的顺序一致
    for choiceDataId, choiceData in ipairs(choiceDataMapper) do
        if choiceDataKey then
            if choiceData[choiceDataKey] == choiceDataValue then
                table.insert(choiceDataList, choiceData)
            end
        else
            if choiceData == choiceDataValue then
                table.insert(choiceDataList, choiceData)
            end
        end
    end
    print("    ----- End: CpiMultiVendor.FindAllByKeyValue(...) ------") -- for debug only
    return choiceDataList
end

return record_lookup_utils
