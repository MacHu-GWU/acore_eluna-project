--[[
这个例子演示了如果用纯 Lua 实现的话, 代码应该是怎样的.

首先这里有几个难点:

1. MENU_DATA_TREE 这个层级结构的 Table 不利于人类输入.
2. 我们需要 Preprocess 这个递归函数将 MENU_DATA_TREE 转换为平铺的 MENU_DATA_MAPPER.

这也是我们为什么要创造 tree_menu Python 库的原因. 它的好处是:

1. 不再需要 MENU_DATA_TREE, 我们直接在 Excel 表格中进行编辑.
2. 不再需要 Preprocess 函数, Python 代码会自动将数据转换为平铺的 MENU_DATA_MAPPER.
3. Python 会自动生成 Lua 中的 MENU_DATA_MAPPER 代码, 你只需要复制粘贴既可.
--]]

local ROOT_PARENT_ID = 0
local GOSSIP_ICON_TRAINER = 3 -- Book
local GOSSIP_ICON_BATTLE = 9 -- Two swords

--[[
MENU_DATA_TREE

把你希望给玩家看到的传送菜单的数据按照层级结构放在这个列表中. 这里的每条记录叫做一个 menuData.
一条 menuData 对应着传送菜单上的一个按钮, 也对应着一个传送坐标.
--]]
local MENU_DATA_TREE = {
    {
        { name = "牧师" },
        {
            { name = "真言术: 韧" },
            { name = "真言术韧 60", buff_id = 10938, buff_count = 1 },
            { name = "真言术韧 70", buff_id = 25389, buff_count = 1 },
            { name = "真言术韧 80", buff_id = 48161, buff_count = 1 },
        },
    },
    {
        { name = "法师" },
        {
            { name = "奥术智慧" },
            { name = "奥术智慧 60", buff_id = 10157, buff_count = 1 },
            { name = "奥术智慧 70", buff_id = 27126, buff_count = 1 },
            { name = "奥术智慧 80", buff_id = 42995, buff_count = 1 },
        },
    },
    {
        { name = "战斗" },
        { name = "兽群领袖光环", buff_id = 24932, buff_count = 1 },
        { name = "枭兽光环", buff_id = 24907, buff_count = 1 },
    },
    { name = "王者祝福", buff_id = 56525, buff_count = 1 },
}

local MENU_DATA_MAPPER = {}
local current_id = 1
local function Preprocess(menuDataTree, parentMenuDataId)
    --[[
    这个函数是对 MENU_DATA_TREE 表中的数据进行解析, 把层级树结构转换为平铺的 key, value
    mapper 结构 (MENU_DATA_MAPPER 这个变量). 这个函数用到了递归.

    :param menuDataTree: 这是一个列表, 里面的元素是类似于
        {name = "达拉然 飞行管理员", map = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0}
        这样的字典.
    :param parentMenuDataId: 这是一个数字, 用于标识当前 menuDataList 的父级菜单.
    --]]
    -- 类似于 Python 中的 enumerate 函数, 返回一个索引和值的元组
    for ind, menuData in ipairs(menuDataTree) do
        newMenuData = {
            id = current_id,
            name = menuData.name,
            is_menu = false,
            icon = GOSSIP_ICON_BATTLE,
            parent_id = parentMenuDataId,
            data = menuData,
        }
        current_id = current_id + 1
        MENU_DATA_MAPPER[newMenuData.id] = newMenuData
        --print(string.format("newMenuData.id = %s, newMenuData.name = %s, newMenuData.is_menu = %s, newMenuData.parent_id = %s", newMenuData.id, newMenuData.name, newMenuData.is_menu, newMenuData.parent_id))

        -- 如果 menuData 是一个菜单, 那么递归调用这个函数
        if not menuData.buff_id then
            MENU_DATA_MAPPER[newMenuData.id].is_menu = true
            MENU_DATA_MAPPER[newMenuData.id].icon = GOSSIP_ICON_TRAINER
            Preprocess(menuData, newMenuData.id)
        end
    end
end

Preprocess(MENU_DATA_TREE, ROOT_PARENT_ID)

local function FindIdByKeyValue(menuDataMapper, menuDataKey, menuDataValue)
    --[[
    这个函数的目的是查找第一个 key, value pair 符合条件的 menuData 的 ID.

    类似于 ``SELECT ID FROM table WHERE talbe.menuDataKey = menuDataValue LIMIT 1``.

    :type menuDataMapper: table
    :param menuDataMapper: 一个 {ID: menuData} 的字典, 其中 ID 是整数.
    :type menuDataKey: string
    :param menuDataKey: menuData 中的 key
    :type menuDataKey: any
    :param menuDataValue: menuData 中的 value

    :return: 符合条件的 menuData 的 ID.
    --]]
    for menuDataId, menuData in pairs(menuDataMapper) do
        if menuDataKey then
            if menuData[menuDataKey] == menuDataValue then
                return menuDataId
            end
        else
            -- 貌似无论如何都不会进入到这段逻辑中
            if menuData == menuDataValue then
                return menuDataId
            end
        end
    end
end

local function FindAllByKeyValue(menuDataMapper, menuDataKey, menuDataValue)
    --[[
    这个函数的目的是查找所有 key, value pair 符合条件的 menuData (不是 ID 而是数据) 的列表.
    类似于 ``SELECT * FROM table WHERE talbe.menuDataKey = menuDataValue``.
    这个函数主要用于根据 parent_id 查找所有子菜单.

    :type menuDataMapper: table
    :param menuDataMapper: 一个 {ID: menuData} 的字典, 其中 ID 是整数.
    :type menuDataKey: string
    :param menuDataKey: menuData 中的 key
    :type menuDataKey: any
    :param menuDataValue: menuData 中的 value

    :return: 符合条件的所有 menuData 的列表.
    --]]
    local menuDataList = {}
    for menuDataId, menuData in pairs(menuDataMapper) do
        if menuDataKey then
            if menuData[menuDataKey] == menuDataValue then
                table.insert(menuDataList, menuData)
            end
        else
            if menuData == menuDataValue then
                table.insert(menuDataList, menuData)
            end
        end
    end
    return menuDataList
end

local function PrintMenuData(menuData)
    print(string.format("---------- %s ----------", menuData.id))
    print(string.format("id = %s", menuData.id))
    print(string.format("name = %s", menuData.name))
    print(string.format("is_menu = %s", menuData.is_menu))
    print(string.format("icon = %s", menuData.icon))
    print(string.format("parent_id = %s", menuData.parent_id))
    print(string.format("data.buff_id = %s", menuData.data.buff_id))
    print(string.format("data.buff_count = %s", menuData.data.buff_count))
end

print("========== MENU_DATA_MAPPER ==========")
for id, menuData in pairs(MENU_DATA_MAPPER) do
    PrintMenuData(menuData)
end

print("========== FindIdByKeyValue ==========")
local menuDataId = FindIdByKeyValue(MENU_DATA_MAPPER, "name", "真言术韧 80")
PrintMenuData(MENU_DATA_MAPPER[menuDataId])

print("========== FindAllByKeyValue ==========")
local menuDataList = FindAllByKeyValue(MENU_DATA_MAPPER, "parent_id", 11)
for _, menuData in pairs(menuDataList) do
    PrintMenuData(menuData)
end
