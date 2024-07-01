--[[
Player Chat Command 是指当玩家在聊天框输入特定的命令时, lua 脚本会执行特殊的操作.

这个库提供了一些类和方法, 方便你编写这一类的应用.
--]]

local record_lookup_utils = require("record_lookup_utils")
local gossip_menu_utils = require("gossip_menu_utils")

local player_chat_command_utils = {}

--[[
这是一个类. 一个 PlayerChatCommandTreeGossipMenuHandler 实例代表着一个特定的聊天命令的处理逻辑.
当玩家在聊天框输入特定的命令时, 会打开一个树形结构的 gossip menu, 点击 menu 中的 option 会
执行 playerActionFunction 函数中定义的业务逻辑.
--]]
player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler = {}
player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler.__index = player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler

--[[
创建一个 PlayerChatCommandTreeGossipMenuHandler 的实例.
--]]
---@alias playerActionFunction fun(player Player, itemGossipOption ItemGossipOptionType)
---  它是一个由点击 gossip option 点击事件触发的业务逻辑处理函数. 其中 player 就是输入命令的玩家,
---  itemGossipOption 就是玩家点击的 gossip option, 它本质上是一个 table, 在 data 字段下可以包含任何数据.

---@param gossipOptionList GossipOptionType[]: 一个包含所有 GossipOption 的列表
---  这也是这个聊天命令的 gossip 菜单数据.
---@param command string, 只有玩家输入的聊天命令等于这个才会触发后续的处理逻辑
---@param gossip_menu_id number, 用于标识 gossip 菜单的 id, 这个值会用来注册 event,
---  不同的 PlayerChatCommandTreeGossipMenuHandler 实例应该有不同的 gossip_menu_id
---  这样不同的 PlayerGossipEvent 就可以根据不同的 gossip_menu_id 来使用不同的实例来处理.
---  这个数不需要在数据库中有对应的数据.
---@param npc_text_id number, 用于在 gossip 菜单中显示的 NPC 文本的 ID
---@param playerActionFunction playerActionFunction, 玩家跟 gossip 菜单中的
---  itemGossipOption 交互时的回调函数
function player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler.new(
        gossipOptionList,
        command,
        gossip_menu_id,
        npc_text_id,
        playerActionFunction
)
    -- init
    local self = setmetatable({}, player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler)
    self.gossipOptionList = gossipOptionList
    self.command = command
    self.gossip_menu_id = gossip_menu_id
    self.npc_text_id = npc_text_id
    self.playerActionFunction = playerActionFunction

    -- post init
    self.gossipOptionDict = record_lookup_utils.MakeRecordDict(
            self.gossipOptionList,
            "id"
    )
    return self
end

--[[
Lua 中方法调用和函数调用有一个常见陷阱. 当用
handler = player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler.new(...)
创建了一个 PlayerChatCommandTreeGossipMenuHandler 的实例后, 再使用
handler.methodName 时，实际上是在获取函数本身, 而不是绑定到实例的方法. 所以我无法将其作为一个
回调函数传递给 eluna 的RegisterXYZEvent 函数. 要解决这个问题, 我需要用闭包将方法绑定到对象.
这个函数可以让你用比较少的代码做到这一点.

比如我想要绑定 PlayerChatCommandTreeGossipMenuHandler.OnChat 方法, 我只需要:

local boundOnChat = PlayerChatCommandTreeGossipMenuHandler:bindMethod("OnChat")

然后我只要想把 PlayerChatCommandTreeGossipMenuHandler.OnChat 方法本身当成一个参数传递给 RegisterPlayerEvent 函数时,
我只需要传递 boundOnChat 即可.
--]]
---@param methodName string, 方法名
function player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler:BindMethod(
        methodName
)
    local method = self[methodName]
    return function(...)
        return method(self, ...)
    end
end

--[[
构建并发送 gossip 菜单. 它是一个语法糖, 把 gossip_menu_utils.BuildGossipMenuItemList 和
gossip_menu_utils.SendGossipMenu 两个函数整合在一起了, 让代码变得更简洁.
--]]
---@param player Player,
---@param parentGossipOptionId number, 这是一个整数, 代表着父菜单的 id.
function player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler:BuildAndSendGossipMenu(
        player,
        parentGossipOptionId
)
    local gossipMenuItemList = gossip_menu_utils.BuildGossipMenuItemList(
            self.gossipOptionList,
            self.gossipOptionDict,
            parentGossipOptionId
    )
    gossip_menu_utils.SendGossipMenu(
            player,
            gossipMenuItemList,
            player,
            self.npc_text_id,
            self.gossip_menu_id
    )
end

--[[
The callback function for Global:RegisterPlayerEvent@PLAYER_EVENT_ON_CHAT event.

处理玩家在聊天框输入文本的事件. 如果玩家输入的文本是特定的命令, 则构建并打开 gossip 菜单.

See https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
--]]
---@param event number, PLAYER_EVENT_ON_CHAT 的数字
---@param player Player,
---@param msg string, 玩家在聊天框输入的消息
---@param Type number,
---@param lang number,
function player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler:OnEnterCommand(
        event,
        player,
        msg,
        _,
        lang
)
    print("#===========================================================")
    print(string.format(
            "# Start a new session at %s",
            os.date("%Y-%m-%d %H:%M:%S")
    ))
    print("#===========================================================")
    print("+---- Start: PlayerChatCommandTreeGossipMenuHandler:OnEnterCommand(...)")
    print(string.format("| event = %s", event))
    print(string.format("| player = %s", player))
    print(string.format("| msg = %s", msg))
    print(string.format("| lang = %s", lang))
    if (msg == self.command) then
        --player:SendNotification("Chat Command Works") -- for debug only
        player:GossipClearMenu()
        self:BuildAndSendGossipMenu(player, gossip_menu_utils.NO_PARENT_ID)
    end
    print("+---- End: PlayerChatCommandTreeGossipMenuHandler:OnEnterCommand(...)")
end


--[[
The callback function for Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_SELECT event.

See https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
--]]
---@param event number, PLAYER_EVENT_ON_CHAT 的数字
---@param player Player,
---@param object Object, 这是玩家正在与之交互的对象. 它可以是 Creature/GameObject/Item/Player
---  但在我们这个应用场景中, 因为菜单是由玩家输入命令触发的, 我们已经有 player 参数了, 所以这个参数用不到.
---@param sender Object, 通常用于标识触发 gossip 事件的源头或者上下文. 它的具体含义可能会根据不同的情况而变化.
---  但在我们这个应用场景中, 因为菜单是由玩家输入命令触发的, 我们已经有 player 参数了, 所以这个参数用不到.
---@param intid number, 这是一个整数标识符, 通常用于识别玩家在 gossip 菜单中选择的特定选项.
---  当你创建用 Player:GossipMenuAddItem 创建 gossip menu 时, 每个选项都会被分配一个唯一的 intid.
---  当玩家选择一个选项时, 这个 intid 会被传递给回调函数, 让你知道玩家选择了哪个选项.
---  See https://www.azerothcore.org/pages/eluna/Player/GossipMenuAddItem.html
---@param code string, 这是一个字符串参数, 通常用于在某些特殊情况下传递额外的信息. 例如,
---  如果 gossip 选项包含一个文本输入框, 玩家输入的文本会通过这个 code 参数传递给回调函数.
---  在大多数简单的 gossip 交互中, 这个参数可能为空或不使用.
---@param menu_id number, only for player gossip. Can return false to do default action.
function player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler:OnSelectOption(
        event,
        player,
        object,
        sender,
        intid,
        code,
        menu_id
)
    print("+---- Start: PlayerChatCommandTreeGossipMenuHandler.OnSelectOption(...)") -- for debug only
    print("| Input parameters: ") -- for debug only
    print(string.format("|   event = %s", event))
    print(string.format("|   player = %s", player))
    print(string.format("|   object = %s", object))
    print(string.format("|   sender = %s", sender))
    print(string.format("|   intid = %d", intid))

    local selectedGossipOption = self.gossipOptionDict[intid]

    print("| Print selectedGossipOption: ")
    print(string.format("|   selectedGossipOption = %s", selectedGossipOption))
    print(string.format("|   id = %s", selectedGossipOption.id))
    print(string.format("|   name = %s", selectedGossipOption.name))
    print(string.format("|   type = %s", selectedGossipOption.type))
    print(string.format("|   icon = %s", selectedGossipOption.icon))
    print(string.format("|   parent = %s", selectedGossipOption.parent))

    -- 这是一个 itemGossipOption, 执行业务逻辑
    if selectedGossipOption.type == "item" then
        print("| Enter itemGossipOption handling logic") -- for debug only
        self.playerActionFunction(player, selectedGossipOption)
        player:GossipComplete()
        print("+---- End: PlayerChatCommandTreeGossipMenuHandler.OnSelectOption(...)") -- for debug only
        return
    end

    -- 这是一个 menuGossipOption, 此时这个 intid 就是 sub menu 的 id.
    if selectedGossipOption.type == "menu" then
        print("| Enter menuGossipOption handling logic") -- for debug only
        self:BuildAndSendGossipMenu(player, intid)
    end
    -- 这是一个 backGossipOption:,此时这个 intid 就是 parent menu 的 id.
    if selectedGossipOption.type == "back" then
        print("| Enter backGossipOption handling logic") -- for debug only
        self:BuildAndSendGossipMenu(player, selectedGossipOption.back_to)
    end
    print("+---- End: PlayerChatCommandTreeGossipMenuHandler.OnSelectOption(...)") -- for debug only
end

function player_chat_command_utils.PlayerChatCommandTreeGossipMenuHandler:RegisterEvents()
    local PLAYER_EVENT_ON_CHAT = 18
    local GOSSIP_EVENT_ON_SELECT = 2

    local PlayerEventOnChatEventHandler = self:BindMethod("OnEnterCommand")
    RegisterPlayerEvent(
            PLAYER_EVENT_ON_CHAT,
            PlayerEventOnChatEventHandler
    )
    local PlayerGossipOnSelectEventHandler = self:BindMethod("OnSelectOption")
    RegisterPlayerGossipEvent(
            self.gossip_menu_id,
            GOSSIP_EVENT_ON_SELECT,
            PlayerGossipOnSelectEventHandler
    )
    --local PlayerEventOnChatEventHandler = PlayChatCommandDemoAddAura.PlayerChatCommandTreeGossipMenuHandler:BindMethod("OnEnterCommand")
    --RegisterPlayerEvent(
    --        PLAYER_EVENT_ON_CHAT,
    --        PlayerEventOnChatEventHandler
    --)
    --local PlayerGossipOnSelectEventHandler = PlayChatCommandDemoAddAura.PlayerChatCommandTreeGossipMenuHandler:BindMethod("OnSelectOption")
    --RegisterPlayerGossipEvent(
    --        self.gossip_menu_id,
    --        GOSSIP_EVENT_ON_SELECT,
    --        PlayerGossipOnSelectEventHandler
    --)
end

return player_chat_command_utils
