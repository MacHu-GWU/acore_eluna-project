--[[
这个脚本用于让玩家通过输入 #tele 命令来打开传送菜单.

Code Style

- 所有函数名称和方法名称都是首字母大写的 camel case. 这是为了跟 elunaengine 的风格保持一致,
    see: https://www.azerothcore.org/pages/eluna/Player/index.html
- 所有的常数变量都是全大写, 用下划线分隔单词.
- 所有的函数的参数都是首字母小写的 camel case. 这也是为了跟 elunaengine 的风格保持一致,
    see: https://www.azerothcore.org/pages/eluna/Player/AddItem.html
--]]

--[[
------------------------------------------------------------------------------
Define Constants
------------------------------------------------------------------------------
--]]
local NPC_TEXT_ID_1 = 1 -- Greetings, $n
local GOSSIP_MENU_ID_21 = 21 -- I don't know
local CHAT_PREFIX = "#tele" -- 玩家在聊天框输入的消息如果以这个开头, 那么就会触发传送菜单

--[[
下面是所有 ICON 代码的枚举. 你可以在 "OptionIcon" 一节中看到所有图标的说明.
See: https://www.azerothcore.org/wiki/gossip_menu_option
--]]
-- See
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

local PLAYER_GOSSIP_MENU_ID = 21

-- 这是我们所有跟 teleport 相关的逻辑的 namespace table
local PlayerChatCommandTeleport = {}

PlayerChatCommandTeleport.STANDARD_TELEPORT_ICON = GOSSIP_ICON_TAXI
PlayerChatCommandTeleport.STANDARD_MENU_ICON = GOSSIP_ICON_TRAINER
--[[
把你希望给玩家看到的传送菜单的数据按照层级结构放在这个表中. 这里的每条记录叫做一个 menuData.
--]]
PlayerChatCommandTeleport.MENU_DATASET = {
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

-- menu builder

--[[
这个变量是最终展现给玩家的菜单的数据容器. 它是类似于一个 Python 字典的结构. 其中 key 是
menuData 的唯一 ID, value 是 menuData 本身.

{
    1: {"name": "...", "mapid": ...},
    2: {"name": "...", "mapid": ...},
    ...
}
--]]
PlayerChatCommandTeleport.Menu = {}

--[[
这个变量是给所有 PlayerChatCommandTeleport.MENU_DATASET 中定义的 menuData 分配一个
唯一的 ID, 以便精确定位. 这个变量会在 PlayerChatCommandTeleport.Analyse 函数中被用到,
每次处理完一个 menuData 就会 + 1.
--]]
local idCount = 1
function PlayerChatCommandTeleport.Analyse(menuDataList, parentMenuDataId)
    --[[
    这个函数是对 PlayerChatCommandTeleport.MENU_DATASET 表中的数据进行解析, 给
    PlayerChatCommandTeleport.Menu 表填充数据. 这个函数用到了递归.

    :param menuDataList: 这是一个列表, 里面的元素是类似于
        {name = "达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0}
        这样的字典.
    :param parentMenuDataId: 这是一个数字, 用于标识当前 menuDataList 的父级菜单.
    --]]
    -- 类似于 Python 中的 enumerate 函数, 返回一个索引和值的元组
    for ind, menuData in ipairs(menuDataList) do
        -- 由 PlayerChatCommandTeleport.Analyse 给 menuData 添加的属性全大写,
        -- 用于和 menuData 中原来就有的属性区分开来.
        -- 给这个 menuData 分配一个唯一的 ID
        menuData.ID = idCount
        -- 记录这个 menuData 的父菜单是哪个, 如果没有父级菜单则设为 0
        menuData.PARENT_ID = parentMenuDataId
        -- 如果 icon 没指定, 就默认用 StandardTeleportIcon (一个小翅膀那个)
        menuData.ICON = menuData.icon or PlayerChatCommandTeleport.STANDARD_TELEPORT_ICON
        idCount = idCount + 1
        -- 将这个 menuData 添加到 PlayerChatCommandTeleport.Menu 表中
        PlayerChatCommandTeleport.Menu[menuData.ID] = menuData

        if not menuData.mapid then
            -- 如果连 map id 都没有, 那么就是一个菜单, 所以把 ICON 设为 StandardMenuIcon (一本书那个)
            PlayerChatCommandTeleport.Menu[menuData.ID].ICON = menuData.icon or PlayerChatCommandTeleport.STANDARD_MENU_ICON
            -- 因为我们知道这是一个菜单, 所以递归调用 PlayerChatCommandTeleport.Analyse 函数
            -- 遍历这个菜单下面的所有 menuData, 并且将它们的 parentMenuDataId 都设为当前 menuData 的 ID
            PlayerChatCommandTeleport.Analyse(menuData, menuData.ID)
        end
    end
end

print("Export Teleports...")
PlayerChatCommandTeleport.Analyse(PlayerChatCommandTeleport.MENU_DATASET, 0)
print("Export complete")

table.find = function(_table, _tofind, _index)
    --[[
    --]]
    for k,v in pairs(_table) do
        if _index then
            if v[_index] == _tofind then
                return k
            end
        else
            if v == _tofind then
                return k
            end
        end
    end
end

table.findall = function(_table, _tofind, _index)
    local result = {}
    for k,v in pairs(_table) do
        if _index then
            if v[_index] == _tofind then
                table.insert(result, v)
            end
        else
            if v == _tofind then
                table.insert(result, v)
            end
        end
    end
    return result
end



function PlayerChatCommandTeleport.BuildMenu(unit, player, from)
    --[[
    这个函数会
    --]]
    local MenuTable = table.findall(
            PlayerChatCommandTeleport.Menu,
            from,
            "FROM"
    )

    --[[
    下面会用 Player:GossipMenuAddItem 方法来添加菜单项

    See: https://www.azerothcore.org/pages/eluna/Player/GossipMenuAddItem.html
    --]]
    for _,entry in ipairs(MenuTable) do
        player:GossipMenuAddItem(entry.ICON, entry.name, 0, entry.ID, entry.pass)
    end
    if from > 0 then
        local GoBack = PlayerChatCommandTeleport.Menu[table.find(PlayerChatCommandTeleport.Menu, from, "ID")].PARENT_ID
        player:GossipMenuAddItem(7, "Back..", 0, GoBack)
    end
    --[[
    Player:GossipSendMenu 用于发送菜单给玩家. 它有三个参数 (因为这里跟玩家对话的对象是玩家自己):
    Player:GossipSendMenu( npc_text, sender, menu_id )

    - number npc_text
        Entry ID of a header text in npc_text database table, common default is 100.
        Valid numbers: integers from 0 to 4,294,967,295.
    - Object sender
        Object acting as the source of the sent gossip menu.
    - number menu_id
        If sender is a Player then menu_id is mandatory.
        Valid numbers: integers from 0 to 4,294,967,295.

    See: https://www.azerothcore.org/pages/eluna/Player/GossipSendMenu.html
    --]]
    local npc_text_id = 1 -- Greetings, $n
    local gossip_menu_id = 21
    player:GossipSendMenu(npc_text_id, unit, gossip_menu_id)
end

--[[
--------------------------------------------------------------------------------
Event Handler Functions
--------------------------------------------------------------------------------
--]]
function PlayerChatCommandTeleport.OnTalk(
    event,
    player,
    object,
    sender,
    intid,
    code,
    menu_id
)
    --[[
    RegisterPlayerGossipEvent | GOSSIP_EVENT_ON_HELLO 的参数列表:

    :param event:
    :param player:
    :param object: Object is the Creature/GameObject/Item. Can return false
        to do default action. For item gossip can return false to stop spell casting.

    RegisterPlayerGossipEvent | GOSSIP_EVENT_ON_SELECT 的参数列表:

    :param event
    :param player
    :param object: Object is the Creature/GameObject/Item/Player
    :param sender:
    :param intid:
    :param code:
    :param menu_id: only for player gossip. Can return false to do default action.


    当 event 是 GOSSIP_EVENT_ON_HELLO, 也就是你第一次打开对话的时候, 那么展示一个 menu.
    这时候函数的入参是 (event, player, object), 所以这里的 Sender, Intid, Code, MenuId 都是空的.
    其中 Event (event) 是 1, Player 是玩家对象, Unit (object) 是玩家互动的对象. 在这个
    例子中对象是一个 NPC, 也就是一个 Creature.
    --]]
    print("Enter function PlayerChatCommandTeleport.OnTalk()")
    if event == 1 or intid == 0 then
        print("Enter branch: if event == 1 or intid == 0 then")
        --print(string.format("Enter branch 1, event = %d, intId = %d", event, intid))
        PlayerChatCommandTeleport.BuildMenu(object, player, 0)
        print("Exit function PlayerChatCommandTeleport.OnTalk()")
    -- 当 event 是 GOSSIP_EVENT_ON_SELECT, 也就是你选择了一个 gossip 中的选项时, 那么进入到后续的处理逻辑
    else
        print("Enter branch: else")
        --print(string.format("Enter branch 2, event = %d, intId = %d", event, intid))
        local M = PlayerChatCommandTeleport.Menu[table.find(PlayerChatCommandTeleport.Menu, intid, "ID")]
        if not M then error("This should not happen") end

        if M.pass then
            if Password ~= M.pass then
                player:SendNotification(PlayerChatCommandTeleport.WrongPassText)
                player:GossipComplete()
                return
            end
        end

        if M.mapid then
            player:Teleport(M.mapid, M.x, M.y, M.z, M.o)
            player:GossipComplete()
            return
        end

        PlayerChatCommandTeleport.BuildMenu(object, player, intid)
        print("Exit function PlayerChatCommandTeleport.OnTalk()")
    end
end

-- entry point
local function PlayerEventCommandHandler(event, player, msg, _, lang)
    --[[
    RegisterPlayerEvent | PLAYER_EVENT_ON_CHAT 的参数列表:

    :param event:
    :param player:
    :param msg: 玩家在聊天框输入的消息
    :param Type:
    :param lang: 语种
    --]]
    print("Enter function PlayerEventCommandHandler()")
    if (msg:find(CHAT_PREFIX) == 1) then
        player:SendNotification("Teleport Chat Command Works")
        --[[
        Player:GossipSendMenu 用于发送菜单给玩家. 它有三个参数 (因为这里跟玩家对话的对象是玩家自己):
        Player:GossipSendMenu( npc_text, sender, menu_id )

        - number npc_text
            Entry ID of a header text in npc_text database table, common default is 100.
            Valid numbers: integers from 0 to 4,294,967,295.
        - Object sender
            Object acting as the source of the sent gossip menu.
        - number menu_id
            If sender is a Player then menu_id is mandatory.
            Valid numbers: integers from 0 to 4,294,967,295.

        See: https://www.azerothcore.org/pages/eluna/Player/GossipSendMenu.html
        --]]
        --local npc_text_id = 1 -- Greetings, $n
        --local gossip_menu_id = 21
        --player:GossipSendMenu(npc_text_id, player, gossip_menu_id)
        PlayerChatCommandTeleport.BuildMenu(player, player, 0)
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
local PLAYER_EVENT_ON_CHAT = 18 -- Fired when a player types a command
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, PlayerEventCommandHandler)

--[[
下面是 RegisterPlayerGossipEvent 的两个 event code
See: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
--]]
local GOSSIP_EVENT_ON_HELLO = 1 -- Fired when a player opens a gossip menu
local GOSSIP_EVENT_ON_SELECT = 2 -- Fired when a player selects a gossip menu option
RegisterPlayerGossipEvent(
    PLAYER_GOSSIP_MENU_ID,
    GOSSIP_EVENT_ON_HELLO,
    PlayerChatCommandTeleport.OnTalk
)
RegisterPlayerGossipEvent(
    PLAYER_GOSSIP_MENU_ID,
    GOSSIP_EVENT_ON_SELECT,
    PlayerChatCommandTeleport.OnTalk
)
