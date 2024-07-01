--[[
当玩家在聊天框输入 #buff 命令后, 弹出一个菜单让玩家选择加的 Buff.
--]]

local gossip_menu_utils = require("gossip_menu_utils")
local player_chat_command_utils = require("player_chat_command_utils")

local BuffMasterPlayerChatCommand = {}
BuffMasterPlayerChatCommand.gossipOptionList = {
    { id = 373001, name = "80级 通用 Buff", type = "item", icon = 9, parent = 0, data = { { id = 56525, count = 1 }, { id = 48161, count = 1 }, { id = 42995, count = 1 }, { id = 48073, count = 1 }, { id = 48469, count = 1 } } },
    { id = 373002, name = "70级 通用 Buff", type = "item", icon = 9, parent = 0, data = { { id = 56525, count = 1 }, { id = 25389, count = 1 }, { id = 27126, count = 1 }, { id = 25312, count = 1 }, { id = 26990, count = 1 } } },
    { id = 373003, name = "60级 通用 Buff", type = "item", icon = 9, parent = 0, data = { { id = 56525, count = 1 }, { id = 10938, count = 1 }, { id = 10157, count = 1 }, { id = 27841, count = 1 }, { id = 9885, count = 1 } } },
    { id = 373004, name = "物理 DPS Buff", type = "item", icon = 9, parent = 0, data = { { id = 48161, count = 1 }, { id = 48469, count = 1 }, { id = 47436, count = 1 }, { id = 56525, count = 1 }, { id = 48942, count = 1 }, { id = 24932, count = 1 }, { id = 34300, count = 1 }, { id = 19506, count = 1 }, { id = 75447, count = 1 }, { id = 58646, count = 1 }, { id = 55610, count = 1 }, { id = 57399, count = 1 }, { id = 53760, count = 1 } } },
    { id = 373005, name = " 法系 DPS Buff", type = "item", icon = 9, parent = 0, data = { { id = 56525, count = 1 }, { id = 48161, count = 1 }, { id = 42995, count = 1 }, { id = 48073, count = 1 }, { id = 48469, count = 1 }, { id = 24907, count = 1 }, { id = 75447, count = 1 }, { id = 54646, count = 1 }, { id = 19746, count = 1 }, { id = 58777, count = 1 }, { id = 57663, count = 1 }, { id = 2895, count = 1 }, { id = 57399, count = 1 }, { id = 53755, count = 1 } } },
    { id = 373006, name = "坦克 Buff", type = "item", icon = 9, parent = 0, data = { { id = 48161, count = 1 }, { id = 48469, count = 1 }, { id = 47440, count = 1 }, { id = 25899, count = 1 }, { id = 48942, count = 1 }, { id = 24932, count = 1 }, { id = 34300, count = 1 }, { id = 19506, count = 1 }, { id = 75447, count = 1 }, { id = 58646, count = 1 }, { id = 55610, count = 1 }, { id = 57399, count = 1 }, { id = 53758, count = 1 } } },
    { id = 373007, name = "治疗 Buff", type = "item", icon = 9, parent = 0, data = { { id = 56525, count = 1 }, { id = 48161, count = 1 }, { id = 42995, count = 1 }, { id = 48073, count = 1 }, { id = 48469, count = 1 }, { id = 24907, count = 1 }, { id = 75447, count = 1 }, { id = 54646, count = 1 }, { id = 19746, count = 1 }, { id = 58777, count = 1 }, { id = 57663, count = 1 }, { id = 2895, count = 1 }, { id = 57399, count = 1 }, { id = 54212, count = 1 } } },
    { id = 373008, name = "物理法术双修 DPS Buff", type = "item", icon = 9, parent = 0, data = { { id = 48161, count = 1 }, { id = 42995, count = 1 }, { id = 48469, count = 1 }, { id = 47436, count = 1 }, { id = 56525, count = 1 }, { id = 48942, count = 1 }, { id = 24932, count = 1 }, { id = 34300, count = 1 }, { id = 19506, count = 1 }, { id = 75447, count = 1 }, { id = 58646, count = 1 }, { id = 57663, count = 1 }, { id = 2895, count = 1 }, { id = 55610, count = 1 }, { id = 57399, count = 1 }, { id = 53760, count = 1 } } },
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
    -- See: https://www.azerothcore.org/pages/eluna/Player/SendListInventory.html
    for _, buff_detail in ipairs(itemGossipOption.data) do
        player:AddAura(buff_detail.id, player)
    end
end

-- 定义玩家输入的命令
local command = "#buff"
-- 定义 gossip menu 的 id, 要确保在有多个类似于这个 App 的情况下, 这个 id 是唯一的
local gossip_menu_id = 103002
-- 定义 gossip menu 的 npc_text_id
local npc_text_id = gossip_menu_utils.DEFAULT_NPC_TEXT_ID

-- 创建一个 PlayerChatCommandTreeGossipMenuHandler 的实例
BuffMasterPlayerChatCommand.TeleportHandler = player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler.new(
        BuffMasterPlayerChatCommand.gossipOptionList,
        command,
        gossip_menu_id,
        npc_text_id,
        PlayerAction
)

-- Register Events
BuffMasterPlayerChatCommand.TeleportHandler:RegisterEvents()
