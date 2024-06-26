-- Projekt: Tablebased multimenu Teleportscript
-- Code: Kenuvis
-- Date: 23.07.2012
-- Convert to Eluna by Rochet2 on 9.6.2015

print("########")
print("Multiteleporter loaded...")

local NPCID = 16781 -- for Both alliance and horde
local teleport = {}

teleport.StandardTeleportIcon = 2
teleport.StandardMenuIcon = 3
teleport.WrongPassText = "Wrong Password!"

teleport.ports = {
    {name = "Location 1", mapid = 1, x = 2, y = 3, z = 4, o = 5},
    {name = "Location 2", mapid = 1, x = 2, y = 3, z = 4, o = 5, pass = "password"},
    --[[
    这里重点说一下 ICON

    - 这篇文档介绍了魔兽世界中 Gossip 菜单中的 ICON: https://wowpedia.fandom.com/wiki/Category:WoW_Icons:_UI_GossipFrame
    - 这篇文档中的 OptionIcon 一节介绍了 Azerothcore 服务器支持的所有 ICON: https://www.azerothcore.org/wiki/gossip_menu_option
    --]]
    {name = "Location 3", mapid = 1, x = 2, y = 3, z = 4, o = 5, icon = 4},
    {name = "SubMenu1",
        {name = "Location 4", mapid = 1, x = 2, y = 3, z = 4, o = 5},
        {name = "Location 5", mapid = 1, x = 2, y = 3, z = 4, o = 5},
        {name = "Location 6", mapid = 1, x = 2, y = 3, z = 4, o = 5},
        {name = "SubSubMenu1",
            {name = "Location 7", mapid = 1, x = 2, y = 3, z = 4, o = 5},
            {name = "Location 8", mapid = 1, x = 2, y = 3, z = 4, o = 5},
            {name = "Location 9", mapid = 1, x = 2, y = 3, z = 4, o = 5},
            {name = "test",
                {name = "Location 7", mapid = 1, x = 2, y = 3, z = 4, o = 5},
                {name = "Location 8", mapid = 1, x = 2, y = 3, z = 4, o = 5},
                {name = "Location 9", mapid = 1, x = 2, y = 3, z = 4, o = 5},
            },
        },
    },
}

------------------------------------------------------------------------------------
-- Nothing change after this! ---------------------------------------------------
------------------------------------------------------------------------------------

local IDcount = 1
teleport.Menu = {}

function teleport.Analyse(list, from)
    for k,v in ipairs(list) do

        v.ID = IDcount
        v.FROM = from
        -- 如果 icon 没指定, 就用 StandardTeleportIcon (一个小翅膀那个)
        v.ICON = v.icon or teleport.StandardTeleportIcon
        IDcount = IDcount + 1
        teleport.Menu[v.ID] = v

        if not v.mapid then
            -- 如果连 map id 都没有, 那么就是一个菜单, 所以用 StandardMenuIcon (一本书那个)
            teleport.Menu[v.ID].ICON = v.icon or teleport.StandardMenuIcon
            teleport.Analyse(v, v.ID)
        end
    end
end

print("Export Teleports...")
teleport.Analyse(teleport.ports, 0)
print("Export complete")

--[[
这个函数是一个在 table 数据结构中查找元素的函数. 具体细节不详.
--]]
table.find = function(_table, _tofind, _index)
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

--[[
3. Build Menu

这个函数用于构建一个 gossip menu. 这个函数不仅在第一次进入 gossip 的时候会被调用,
在点击 gossip 中的菜单按钮时也会被调用.
--]]
function teleport.BuildMenu(Unit, Player, from)
    local MenuTable = table.findall(teleport.Menu, from, "FROM")

    for _,entry in ipairs(MenuTable) do
        Player:GossipMenuAddItem(entry.ICON, entry.name, 0, entry.ID, entry.pass)
    end
    if from > 0 then
        local GoBack = teleport.Menu[table.find(teleport.Menu, from, "ID")].FROM
        Player:GossipMenuAddItem(7, "Back..", 0, GoBack)
    end
    Player:GossipSendMenu(1, Unit)
end

--[[
2. Main event handler

这是 gossip event handler 函数. 根据
https://www.azerothcore.org/pages/eluna/Global/RegisterCreatureGossipEvent.html
文档, 当 event 是 GOSSIP_EVENT_ON_SELECT 时它的参数是 (event, player, object, sender, intid, code, menu_id)
而我们只用到了 (_, player, object, _, intid, code, _) 这几参数. (它声明了 event 但没有用到).
player 就是目前的玩家; object 就是玩家互动的对象, 这里我们的设定是跟 NPC 互动, 所以实际上是一个 creature;
sender
--]]
function teleport.OnTalk(Event, Player, Unit, _, ID, Password)
    --[[
    当 event 是 GOSSIP_EVENT_ON_HELLO, 也就是你第一次打开对话的时候, 那么展示一个 menu.
    这时候函数的入参是 (event, player, object), 所以这里的 ID 和 Password 都是 nil.
    其中 Event (event) 是 1, Player 是玩家对象, Unit (object) 是玩家互动的对象. 在这个
    例子中对象是一个 NPC, 也就是一个 Creature.
    --]]
    if Event == 1 or ID == 0 then
        teleport.BuildMenu(Unit, Player, 0)
    -- 当 event 是 GOSSIP_EVENT_ON_SELECT, 也就是你选择了一个 gossip 中的选项时, 那么进入到后续的处理逻辑
    else
        local M = teleport.Menu[table.find(teleport.Menu, ID, "ID")]
        if not M then error("This should not happen") end

        if M.pass then
            if Password ~= M.pass then
                Player:SendNotification(teleport.WrongPassText)
                Player:GossipComplete()
                return
            end
        end

        if M.mapid then
            Player:Teleport(M.mapid, M.x, M.y, M.z, M.o)
            Player:GossipComplete()
            return
        end

        teleport.BuildMenu(Unit, Player, ID)
    end
end

--[[
1. Entry point

我们这个脚本监控的是跟某个特定的 NPC gossip 对话的事件. 这个 NPCID 在脚本开头定义了.
你可以在 https://wotlk.evowow.com/?npcs 数据库中查找 NPC id, 也可以在游戏中用命令 .npc info
来查看 (英文客户端显示的 "entry" 后面的数字, 而中文客户端显示的 "阵营" 后面的数字).

- RegisterCreatureGossipEvent 的文档: https://www.azerothcore.org/pages/eluna/Global/RegisterCreatureGossipEvent.html
--]]
print("Register NPC: "..NPCID)
RegisterCreatureGossipEvent(NPCID, 1, teleport.OnTalk)
RegisterCreatureGossipEvent(NPCID, 2, teleport.OnTalk)

print("Multiteleporter loading complete")
print("########")