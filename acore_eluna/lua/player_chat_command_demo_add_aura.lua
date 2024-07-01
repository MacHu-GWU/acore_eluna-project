--[[
一个用于演示如何使用 player_chat_command_utils 创建一个档玩家输入 #addaura 命令后,
打开一个 gossip 菜单来挑选 buff, 点击选项后加 buff 的自定义功能.

这只是一个例子, 根据这个例子你可以定义更多的命令, 以及自己决定点击选项后会发生什么事情.
例如可以做到点击后传送, 给予物品, 打开商店银行等等.
--]]

local gossip_menu_utils = require("gossip_menu_utils")
local player_chat_command_utils = require("player_chat_command_utils")

local PlayChatCommandDemoAddAura = {}
PlayChatCommandDemoAddAura.gossipOptionList = {
    { id = 1001, name = "牧师", type = "menu", icon = 3, parent = 0 },
    { id = 1002, name = "真言术韧", type = "menu", icon = 3, parent = 1001 },
    { id = 1003, name = "真言术韧 60", type = "item", icon = 9, parent = 1002, data = { buff_id = 10938, buff_count = 1 } },
    { id = 1004, name = "真言术韧 70", type = "item", icon = 9, parent = 1002, data = { buff_id = 25389, buff_count = 1 } },
    { id = 1005, name = "真言术韧 80", type = "item", icon = 9, parent = 1002, data = { buff_id = 48161, buff_count = 1 } },
    { id = 1006, name = "Back to 牧师", type = "back", icon = 7, parent = 1002, back_to = 1001 },
    { id = 1007, name = "Back to Top", type = "back", icon = 7, parent = 1002, back_to = 0 },
    { id = 1008, name = "反恐惧结界", type = "item", icon = 9, parent = 1001, data = { buff_id = 6346, buff_count = 1 } },
    { id = 1009, name = "能量灌注", type = "item", icon = 9, parent = 1001, data = { buff_id = 10060, buff_count = 1 } },
    { id = 1010, name = "Back to Top", type = "back", icon = 7, parent = 1001, back_to = 0 },
    { id = 1011, name = "王者祝福", type = "item", icon = 9, parent = 0, data = { buff_id = 56525, buff_count = 1 } },
}

--[[
定义了点击选项后的行为. 也是这个 App 最关键的函数.
在这个例子中, 点击选项后会给玩家加 buff.
--]]
---@param player Player,
---@param itemGossipOption ItemGossipOptionType,
local function PlayerAction(
        player,
        itemGossipOption
)
    -- Ref: https://www.azerothcore.org/pages/eluna/Unit/AddAura.html
    player:AddAura(itemGossipOption.data.buff_id, player)
end

-- 定义玩家输入的命令
local command = "#addaura"
-- 定义 gossip menu 的 npc_text_id
local npc_text_id = gossip_menu_utils.DEFAULT_NPC_TEXT_ID

PlayChatCommandDemoAddAura.PlayerChatCommandTreeGossipMenuHandler = player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler.new(
        PlayChatCommandDemoAddAura.gossipOptionList,
        command,
        npc_text_id,
        PlayerAction
)

--[[----------------------------------------------------------------------------
Register Events
------------------------------------------------------------------------------]]
local PLAYER_EVENT_ON_CHAT = 18
local GOSSIP_EVENT_ON_SELECT = 2

local PlayerEventOnChatEventHandler = PlayChatCommandDemoAddAura.PlayerChatCommandTreeGossipMenuHandler:BindMethod("OnChat")

RegisterPlayerEvent(
        PLAYER_EVENT_ON_CHAT,
        PlayerEventOnChatEventHandler
)

local PlayerGossipOnSelectEventHandler = PlayChatCommandDemoAddAura.PlayerChatCommandTreeGossipMenuHandler:BindMethod("OnSelectOption")

RegisterPlayerGossipEvent(
        gossip_menu_utils.NO_GOSSIP_MENU_ID,
        GOSSIP_EVENT_ON_SELECT,
        PlayerGossipOnSelectEventHandler
)
