--[[
这个脚本是一个基于 ``player_tele_chat_command_event_callback_poc.lua`` 的进阶版本,
它能让玩家通过输入 #tele 命令来打开传送菜单, 然后点击选项传送.
--]]

--[[
------------------------------------------------------------------------------
Define Constants
------------------------------------------------------------------------------
--]]

--[[
EVENT_CODE

所有我们这个脚本用到的 event.

Reference:

- RegisterPlayerEvent: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
- RegisterPlayerGossipEvent: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
--]]
local PLAYER_EVENT_ON_CHAT = 18 -- Fired when a player types a command
local GOSSIP_EVENT_ON_SELECT = 2 -- Fired when a player selects a gossip menu option

--[[
下面是所有 ICON 代码的枚举. 你可以在 "OptionIcon" 一节中看到所有图标的说明.
See: https://www.azerothcore.org/wiki/gossip_menu_option
--]]
local GOSSIP_ICON_CHAT = 0 -- White chat bubble
local GOSSIP_ICON_VENDOR = 1 -- Brown bag
local GOSSIP_ICON_TAXI = 2 -- Flight
local GOSSIP_ICON_TRAINER = 3 -- Book
local GOSSIP_ICON_INTERACT_1 = 4 -- Interaction wheel
local GOSSIP_ICON_INTERACT_2 = 5 -- Interaction wheel
local GOSSIP_ICON_MONEY_BAG = 6 -- Brown bag with yellow dot (gold)
local GOSSIP_ICON_TALK = 7 -- White chat bubble with black dots (...)
local GOSSIP_ICON_TABARD = 8 -- Tabard
local GOSSIP_ICON_BATTLE = 9 -- Two swords
local GOSSIP_ICON_DOT = 10 -- Yellow dot

--[[
下面是所有跟业务逻辑有关的常量.
--]]
local NPC_TEXT_ID_1 = 1 -- Greetings, $n
local PLAYER_GOSSIP_MENU_ID = 21 -- A menu ID for test
local EMPTY_SENDER = 0 -- 用于标识没有 sender 的情况
local CHAT_COMMAND_TELEPORT = "#tele" -- 玩家在聊天框输入的消息如果是这个, 那么就会触发传送菜单
local ROOT_MENU_DATA_PARENT_ID = 0 -- 如果一个菜单没有 parent, 那么它的 PARENT_ID 属性的值就是这个

--[[
这是我们所有跟 teleport 相关的逻辑的 namespace table. 它类似于面向对象中的类一样, 有属性也有方法.

例如后面的 TeleportPlayerChatCommand.OnGossip() 就是一个方法.
--]]
local TeleportPlayerChatCommand = {}

--[[
MENU_DATA_LIST

把你希望给玩家看到的传送菜单的数据按照层级结构放在这个列表中. 这里的每条记录叫做一个 menuData.
一条 menuData 对应着传送菜单上的一个按钮, 也对应着一个传送坐标.
--]]
TeleportPlayerChatCommand.MENU_DATA_LIST = {
    {name = "达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0},
    {name = "达拉然 公共旅馆", mapid = 571, x = 5848.9, y = 636.3, z = 647.5, o = 0},
    {name = "子菜单 1",
        {name = "子菜单 1 达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0},
        {name = "子菜单 1 达拉然 公共旅馆", mapid = 571, x = 5848.9, y = 636.3, z = 647.5, o = 0},
    },
    {name = "子菜单 2",
        {name = "子菜单 2 达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0},
        {name = "子菜单 2 达拉然 公共旅馆", mapid = 571, x = 5848.9, y = 636.3, z = 647.5, o = 0},
    },
}

--[[
MENU_DATA_MAPPER

这个变量是最终展现给玩家的菜单的数据容器. 它是类似于一个 Python 字典的结构. 其中 key 是
menuData 的唯一 ID, value 是 menuData 本身.

{
    1: {"name": "...", "mapid": ...},
    2: {"name": "...", "mapid": ...},
    ...
}
--]]
TeleportPlayerChatCommand.MENU_DATA_MAPPER = {}

--[[
这个变量是给所有 TeleportPlayerChatCommand.MENU_DATA_LIST 中定义的 menuData 分配一个
唯一的 ID, 以便精确定位. 这个变量会在 TeleportPlayerChatCommand.Analyse 函数中被用到,
每次处理完一个 menuData 就会 + 1.
--]]
local idCount = 1
function TeleportPlayerChatCommand.Preprocess(menuDataList, parentMenuDataId)
    --[[
    这个函数是对 TeleportPlayerChatCommand.MENU_DATA_LIST 表中的数据进行解析, 给
    TeleportPlayerChatCommand.MENU_DATA_MAPPER 表填充数据. 这个函数用到了递归.

    :param menuDataList: 这是一个列表, 里面的元素是类似于
        {name = "达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0}
        这样的字典.
    :param parentMenuDataId: 这是一个数字, 用于标识当前 menuDataList 的父级菜单.
    --]]
    -- 类似于 Python 中的 enumerate 函数, 返回一个索引和值的元组
    for ind, menuData in ipairs(menuDataList) do
        -- 由 TeleportPlayerChatCommand.Analyse 给 menuData 添加的属性全大写,
        -- 用于和 menuData 中原来就有的属性区分开来.
        -- 给这个 menuData 分配一个唯一的 ID
        menuData.ID = idCount
        -- 记录这个 menuData 的父菜单是哪个, 如果没有父级菜单则设为 0
        menuData.PARENT_ID = parentMenuDataId
        -- 如果 icon 没指定, 就默认用 Taxi (一个小翅膀那个)
        menuData.ICON = menuData.icon or GOSSIP_ICON_TAXI
        idCount = idCount + 1
        -- 将这个 menuData 添加到 TeleportPlayerChatCommand.MENU_DATA_MAPPER 表中
        TeleportPlayerChatCommand.MENU_DATA_MAPPER[menuData.ID] = menuData
        print(string.format("menuData.ID = %s, menuData.PARENT_ID = %s, menuData.name = %s", menuData.ID, menuData.PARENT_ID, menuData.name))

        if not menuData.mapid then
            -- 如果连 map id 都没有, 那么就是一个菜单, 所以把 ICON 设为 Trainer (一本书那个)
            TeleportPlayerChatCommand.MENU_DATA_MAPPER[menuData.ID].ICON = menuData.icon or GOSSIP_ICON_TRAINER
            -- 因为我们知道这是一个菜单, 所以递归调用 TeleportPlayerChatCommand.Analyse 函数
            -- 遍历这个菜单下面的所有 menuData, 并且将它们的 parentMenuDataId 都设为当前 menuData 的 ID
            TeleportPlayerChatCommand.Preprocess(menuData, menuData.ID)
        end
    end
end

print("Start: convert TeleportPlayerChatCommand.MENU_DATA_LIST to TeleportPlayerChatCommand.MENU_DATA_MAPPER ...")
TeleportPlayerChatCommand.Preprocess(TeleportPlayerChatCommand.MENU_DATA_LIST, 0)
print("End: convert TeleportPlayerChatCommand.MENU_DATA_LIST to TeleportPlayerChatCommand.MENU_DATA_MAPPER ...")

function TeleportPlayerChatCommand.FindIdByKeyValue(menuDataMapper, menuDataKey, menuDataValue)
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
        else -- 貌似无论如何都不会进入到这段逻辑中
            if menuData == menuDataValue then
                return menuDataId
            end
        end
    end
end

function TeleportPlayerChatCommand.FindAllByKeyValue(menuDataMapper, menuDataKey, menuDataValue)
    --[[
    这个函数的目的是查找所有 key, value pair 符合条件的 menuData 的列表.

    类似于 ``SELECT ID FROM table WHERE talbe.menuDataKey = menuDataValue``.

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

function TeleportPlayerChatCommand.BuildMenu(sender, player, parentMenuDataId)
    --[[
    这个函数会是我们用来构建菜单的自定义函数.
    --]]

    --[[
    1. 先根据当前给定的 parentMenuDataId 找到所有的子菜单. 如果 parentMenuDataId 是 0,
    那么就是最顶层的菜单.
    --]]
    local arg_menuDataMapper = TeleportPlayerChatCommand.MENU_DATA_MAPPER
    local arg_menuDataKey = "PARENT_ID"
    local arg_menuDataValue = parentMenuDataId
    local menuDataList = TeleportPlayerChatCommand.FindAllByKeyValue(
        arg_menuDataMapper,
        arg_menuDataKey,
        arg_menuDataValue
    )

    --[[
    这后面的代码会频繁调用 Player:GossipMenuAddItem(...)

    Player:GossipMenuAddItem 方法用于给 Player 当前的 gossip menu 添加一个 item
    (一个 item 就是一个对话面板上可点击的按钮). 这个方法最多接受 7 个参数, 在我们的脚本里
    我们只用到了 4 个.

    :param icon (number): Number that specifies used icon.
        Valid numbers: integers from 0 to 4,294,967,295.
    :param msg (string): Label on the gossip item.
    :param sender (number): Number passed to gossip handlers.
        Valid numbers: integers from 0 to 4,294,967,295.
        通常用于识别谁触发了这个 gossip 选项, 我们这里不需要区分, 所以永远传 0.
    :param intid (number): Number passed to gossip handlers.
        Valid numbers: integers from 0 to 4,294,967,295.

    Ref: https://www.azerothcore.org/pages/eluna/Player/GossipMenuAddItem.html
    --]]

    for _, menuData in ipairs(menuDataList) do
        local arg_icon = menuData.ICON
        local arg_msg = menuData.name
        local arg_sender = EMPTY_SENDER
        local arg_intid = menuData.ID -- 这个 item 的唯一 ID
        player:GossipMenuAddItem(
            arg_icon,
            arg_msg,
            arg_sender,
            arg_intid
        )
    end

    --[[
    2. 如果 parentMenuDataId 大于 0, 说明我们在一个子菜单中, 那么我们需要添加一个返回上一级菜单的选项.
    --]]
    if parentMenuDataId > 0 then
        arg_menuDataMapper = TeleportPlayerChatCommand.MENU_DATA_MAPPER
        arg_menuDataKey = "ID"
        arg_menuDataValue = parentMenuDataId
        print(string.format("Try to find "))
        local menuDataId = TeleportPlayerChatCommand.FindIdByKeyValue(
            arg_menuDataMapper,
            arg_menuDataKey,
            arg_menuDataValue
        )

        local arg_icon = GOSSIP_ICON_TALK
        local arg_msg = "Back to "
        local arg_sender = EMPTY_SENDER
        local arg_intid = TeleportPlayerChatCommand.MENU_DATA_MAPPER[menuDataId].PARENT_ID
        player:GossipMenuAddItem(arg_icon, arg_msg, arg_sender, arg_intid)
    end

    --[[
     Player:GossipSendMenu 方法可以用来发送菜单给玩家. 它的参数列表如下:

    :type npc_text: number
    :param npc_text: Entry ID of a header text in npc_text database table, common default is 100.
        Valid numbers: integers from 0 to 4,294,967,295.
    :type sender: Object
    :param sender: Object acting as the source of the sent gossip menu.
    :type menu_id: number
    :param menu_id: If sender is a Player then menu_id is mandatory.
        Valid numbers: integers from 0 to 4,294,967,295.

    See: https://www.azerothcore.org/pages/eluna/Player/GossipSendMenu.html
    --]]
    player:GossipSendMenu(NPC_TEXT_ID_1, sender, PLAYER_GOSSIP_MENU_ID)
end

--[[
--------------------------------------------------------------------------------
Event Handler Functions
--------------------------------------------------------------------------------
--]]
function TeleportPlayerChatCommand.OnGossip(
    event,
    player,
    object,
    sender,
    intid,
    code,
    menu_id
)
    --[[
    这个函数被用于处理 Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_SELECT event.

    在其他例子中你可能会看到还有一个相关的函数 Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_HELLO event
    用于处理玩家的第一次打开 gossip 菜单的情况. 但是在这个例子中, 打开菜单的动作是通过
    Player:GossipSendMenu() 方法在 TeleportPlayerChatCommand.OnChat() 中手动用代码
    运行的, 而不是通过游戏中 Player 与人互动. 所以我们不会需要处理这个 event. 但这里我们还是
    将它的参数列表文档列出来, 供你了解.

    Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_HELLO 的参数列表:

    :param event:
    :param player (Object):
    :param object (Object): the Creature/GameObject/Item/Player
        这是玩家正在与之交互的对象. 它可以是:
        - Creature (NPC)
        - GameObject (游戏中的物体, 如邮箱, 宝箱等)
        - Item (物品, 如可以右键点击打开菜单的任务物品)
        - Player (在玩家之间的 gossip 交互中)

    Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_SELECT 的参数列表:

    :param event:
    :param player (Object):
    :param object (Object): the Creature/GameObject/Item/Player
        这是玩家正在与之交互的对象. 它可以是:
        - Creature (NPC)
        - GameObject (游戏中的物体, 如邮箱, 宝箱等)
        - Item (物品, 如可以右键点击打开菜单的任务物品)
        - Player (在玩家之间的 gossip 交互中)
    :param sender: 通常用于标识触发 gossip 事件的源头或者上下文. 它的具体含义可能会根据不同的情况而变化:
        - 对于 Creature（NPC）gossip：sender 通常是 NPC 的 GUID. 这可以用来确认是哪个具体的
            NPC 实例触发了事件, 特别是在有多个同类型 NPC 的情况下.
        - 对于 GameObject gossip: sender 同样可能是触发事件的游戏对象的 GUID.
        - 对于 Item gossip: sender 可能表示物品在玩家背包中的位置或者物品的 GUID.
        - 对于 Player gossip (比如玩家之间的交互): sender 可能是发起交互的玩家的 GUID.
    :param intid (number): 这是一个整数标识符, 通常用于识别玩家在 gossip 菜单中选择的特定选项.
        当你创建 gossip 菜单时, 每个选项都会被分配一个唯一的 intid. 当玩家选择一个选项时,
        这个 intid 会被传递给回调函数, 让你知道玩家选择了哪个选项.
    :param code (string): 这是一个字符串参数, 通常用于在某些特殊情况下传递额外的信息. 例如,
        如果 gossip 选项包含一个文本输入框, 玩家输入的文本会通过这个 code 参数传递给回调函数.
        在大多数简单的 gossip 交互中, 这个参数可能为空或不使用.
    :param menu_id (number): only for player gossip. Can return false to do default action.

    Ref: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
    --]]
    print("Enter: TeleportPlayerChatCommand.OnGossip(...)")
    --[[
    打印出 callback 参数的值
    --]]
    print(string.format("event = %s", event))
    print(string.format("player = %s", player))
    print(string.format("object = %s", object))
    print(string.format("sender = %s", sender))
    print(string.format("intid = %d", intid))
    --if event == 1 or intid == 0 then
    if event == GOSSIP_EVENT_ON_SELECT then
        print("Enter: GOSSIP_EVENT_ON_SELECT branch")
        --[[
        这里是你选择了一个 gossip 选项后的处理逻辑, intid 是当前选择的选项的 ID.
        这里会尝试根据 ID 获得这个 menuData 的 ID. (我觉得可能可以直接用
        TeleportPlayerChatCommand.MENU_DATA_MAPPER[intid] 不知道为什么原作者没有这么做,
        可能原作者想要防御性编程吧).
        --]]
        local menuDataMapper = TeleportPlayerChatCommand.MENU_DATA_MAPPER
        local menuDataKey = "ID"
        local menuDataValue = intid
        local menuDataId = TeleportPlayerChatCommand.FindIdByKeyValue(
            menuDataMapper,
            menuDataKey,
            menuDataValue
        )
        print(string.format("Player select the %s item", intid))
        local menuData = TeleportPlayerChatCommand.MENU_DATA_MAPPER[menuDataId]
        if not menuData then
            error("This should not happen")
        end
        -- 获得了被选中的 menuData, 就进入到后续的处理逻辑
        -- 如果 menuData 中有 mapid 字段, 那么就需要传送玩家
        if menuData.mapid then
            player:Teleport(menuData.mapid, menuData.x, menuData.y, menuData.z, menuData.o)
            player:GossipComplete()
            print("Exit: TeleportPlayerChatCommand.OnGossip(...)")
            return
        end

        --[[
        如果 menuData 中既没有 mapid 字段, 那么有两种情况:

        1. 这是一个 submenu 的 gossip item: 此时这个 intid 就是 submenu 的 ID.
            我们将其穿给 TeleportPlayerChatCommand.BuildMenu 既可进入到下一级菜单.
        2. 这是一个 "返回" 的 gossip item: 此时这个 intid ... TODO 完善这里的文档.
        --]]
        local arg_sender = object
        TeleportPlayerChatCommand.BuildMenu(arg_sender, player, intid)
        print("Exit: GOSSIP_EVENT_ON_SELECT branch")
    end
    print("Exit: TeleportPlayerChatCommand.OnGossip(...)")
end

-- entry point
function TeleportPlayerChatCommand.OnChat(event, player, msg, _, lang)
    --[[
    Global:RegisterPlayerEvent@PLAYER_EVENT_ON_CHAT 的参数列表:

    :param event:
    :param player:
    :param msg: 玩家在聊天框输入的消息
    :param Type:
    :param lang: 语种

    See https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
    --]]
    print("Enter function TeleportPlayerChatCommand.OnChat()")
    print(string.format("event = %s", event))
    print(string.format("player = %s", player))
    print(string.format("msg = %s", msg))
    print(string.format("lang = %s", lang))
    if (msg == CHAT_COMMAND_TELEPORT) then
        player:SendNotification("Teleport Chat Command Works")

        -- 首先清空已有的 gossip menu, 确保每次玩家输入 #tele 命令时菜单都是新的.
        player:GossipClearMenu()

        -- 然后调用 TeleportPlayerChatCommand.BuildMenu 函数来构建传送菜单.
        local arg_sender = player
        TeleportPlayerChatCommand.BuildMenu(arg_sender, player, ROOT_MENU_DATA_PARENT_ID)
    end
end

--[[
--------------------------------------------------------------------------------
Register Events
--------------------------------------------------------------------------------
--]]
--[[
下面是 RegisterPlayerEvent 的 event code.
See: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
--]]
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, TeleportPlayerChatCommand.OnChat)

--[[
下面是 RegisterPlayerGossipEvent 的 event code
See: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
--]]
RegisterPlayerGossipEvent(
    PLAYER_GOSSIP_MENU_ID,
    GOSSIP_EVENT_ON_SELECT,
    TeleportPlayerChatCommand.OnGossip
)
print("========== player_tele_chat_command.lua is ready to use ==========")
