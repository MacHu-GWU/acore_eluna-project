--[[
Creature Gossip 是指当玩家跟特定的 NPC 互动时, lua 脚本会执行特殊的操作.

这个库提供了一些类和方法, 方便你编写这一类的应用.
--]]

local record_lookup_utils = require("record_lookup_utils")
local gossip_menu_utils = require("gossip_menu_utils")

local GOSSIP_EVENT_ON_HELLO = 1
local GOSSIP_EVENT_ON_SELECT = 2

local creature_gossip_utils = {}

--[[
这是一个类. 一个 NpcTreeGossipMenuHandler 实例代表着一个特定的聊天命令的处理逻辑.
当玩家跟特定 NPC 互动时, 会打开一个树形结构的 gossip menu, 点击 menu 中的 option 会
执行 playerActionFunction 函数中定义的业务逻辑.
--]]
---@class NpcTreeGossipMenuHandler
---@field gossipOptionList GossipOptionType[]
---@field creature_template_entry number
---@field gossip_menu_id number
---@field npc_text_id number
---@field playerActionFunction playerActionFunction
creature_gossip_utils.NpcTreeGossipMenuHandler = {}
creature_gossip_utils.NpcTreeGossipMenuHandler.__index = creature_gossip_utils.NpcTreeGossipMenuHandler

--[[
创建一个 NpcTreeGossipMenuHandler 的实例.
--]]
---@alias playerActionFunction fun(player Player, creature Creature, itemGossipOption ItemGossipOptionType)
---  它是一个由点击 gossip option 点击事件触发的业务逻辑处理函数. 其中
---  player 就是输入命令的玩家,
---  creature 就是玩家正在互动的 NPC,
---  itemGossipOption 就是玩家点击的 gossip option, 它本质上是一个 table, 在 data 字段下可以包含任何数据.

---@param gossipOptionList GossipOptionType[] 一个包含所有 GossipOption 的列表
---  这也是这个聊天命令的 gossip 菜单数据.
---@param creature_template_entry number 跟哪个 NPC 互动时会触发这个 gossip 菜单
---@param gossip_menu_id number 用于标识 gossip 菜单的 id, 这个值会用来注册 event,
---  不同的 NpcTreeGossipMenuHandler 实例应该有不同的 gossip_menu_id
---  这样不同的 PlayerGossipEvent 就可以根据不同的 gossip_menu_id 来使用不同的实例来处理.
---  这个数不需要在数据库中有对应的数据.
---@param npc_text_id number 用于在 gossip 菜单中显示的 NPC 文本的 ID
---@param playerActionFunction playerActionFunction 玩家跟 gossip 菜单中的
---  itemGossipOption 交互时的回调函数
function creature_gossip_utils.NpcTreeGossipMenuHandler.new(
        gossipOptionList,
        creature_template_entry,
        gossip_menu_id,
        npc_text_id,
        playerActionFunction
)
    -- init
    local self = setmetatable({}, creature_gossip_utils.NpcTreeGossipMenuHandler)
    self.gossipOptionList = gossipOptionList
    self.creature_template_entry = creature_template_entry
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
handler = creature_gossip_utils.NpcTreeGossipMenuHandler.new(...)
创建了一个 NpcTreeGossipMenuHandler 的实例后, 再使用
handler.methodName 时，实际上是在获取函数本身, 而不是绑定到实例的方法. 所以我无法将其作为一个
回调函数传递给 eluna 的 RegisterXYZEvent 函数. 要解决这个问题, 我需要用闭包将方法绑定到对象.
这个函数可以让你用比较少的代码做到这一点.

比如我想要绑定 NpcTreeGossipMenuHandler.OnGossip 方法, 我只需要:

local boundOnChat = NpcTreeGossipMenuHandler:bindMethod("OnGossip")

然后我只要想把 NpcTreeGossipMenuHandler.OnGossip 方法本身当成一个参数传递给
RegisterPlayerEvent 函数时, 我只需要传递 boundOnChat 即可.
--]]
---@param methodName string, 方法名
function creature_gossip_utils.NpcTreeGossipMenuHandler:BindMethod(
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
---@param player Player
---@param creature Creature
---@param parentGossipOptionId number 这是一个整数, 代表着父菜单的 id.
function creature_gossip_utils.NpcTreeGossipMenuHandler:BuildAndSendGossipMenu(
        player,
        creature,
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
            creature,
            self.npc_text_id,
            self.gossip_menu_id
    )
end

--[[
The callback function for Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_SELECT event.

See https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
--]]
---@param event number PLAYER_EVENT_ON_CHAT 的数字
---@param player Player
---@param object Object 这是玩家正在与之交互的对象. 它可以是 Creature/GameObject/Item/Player
---  但在我们这个应用场景中, 因为菜单是由玩家输入命令触发的, 我们已经有 player 参数了, 所以这个参数用不到.
---@param sender Object 通常用于标识触发 gossip 事件的源头或者上下文. 它的具体含义可能会根据不同的情况而变化.
---  但在我们这个应用场景中, 因为菜单是由玩家输入命令触发的, 我们已经有 player 参数了, 所以这个参数用不到.
---@param intid number 这是一个整数标识符, 通常用于识别玩家在 gossip 菜单中选择的特定选项.
---  当你创建用 Player:GossipMenuAddItem 创建 gossip menu 时, 每个选项都会被分配一个唯一的 intid.
---  当玩家选择一个选项时, 这个 intid 会被传递给回调函数, 让你知道玩家选择了哪个选项.
---  See https://www.azerothcore.org/pages/eluna/Player/GossipMenuAddItem.html
---@param code string 这是一个字符串参数, 通常用于在某些特殊情况下传递额外的信息. 例如,
---  如果 gossip 选项包含一个文本输入框, 玩家输入的文本会通过这个 code 参数传递给回调函数.
---  在大多数简单的 gossip 交互中, 这个参数可能为空或不使用.
---@param menu_id number only for player gossip. Can return false to do default action.
function creature_gossip_utils.NpcTreeGossipMenuHandler:OnGossip(
        event,
        player,
        object,
        sender,
        intid,
        code,
        menu_id
)
    if event == GOSSIP_EVENT_ON_HELLO then
        print("#===========================================================")
        print(string.format(
                "# Start a new session at %s",
                os.date("%Y-%m-%d %H:%M:%S")
        ))
        print("#===========================================================")
    end

    print("+---- Start: NpcTreeGossipMenuHandler.OnGossip(...)") -- for debug only
    print("| Input parameters: ") -- for debug only
    print(string.format("|   event = %s", event))
    print(string.format("|   player = %s", player))
    print(string.format("|   object = %s", object))
    print(string.format("|   sender = %s", sender))
    print(string.format("|   intid = %s", intid))

    if event == GOSSIP_EVENT_ON_HELLO then
        print("| Enter GOSSIP_EVENT_ON_HELLO handling logic") -- for debug only
        self:BuildAndSendGossipMenu(player, object, gossip_menu_utils.NO_PARENT_ID)
    elseif event == GOSSIP_EVENT_ON_SELECT then
        print("| Enter GOSSIP_EVENT_ON_SELECT handling logic") -- for debug only
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
            self.playerActionFunction(player, object, selectedGossipOption)
            player:GossipComplete()
            print("+---- End: NpcTreeGossipMenuHandler.OnGossip(...)") -- for debug only
            return
        end

        -- 这是一个 menuGossipOption, 此时这个 intid 就是 sub menu 的 id.
        if selectedGossipOption.type == "menu" then
            print("| Enter menuGossipOption handling logic") -- for debug only
            self:BuildAndSendGossipMenu(player, object, intid)
        end
        -- 这是一个 backGossipOption:,此时这个 intid 就是 parent menu 的 id.
        if selectedGossipOption.type == "back" then
            print("| Enter backGossipOption handling logic") -- for debug only
            self:BuildAndSendGossipMenu(player, object, selectedGossipOption.back_to)
        end
    else
        error(string.format("Invalid event: %s", event))
    end
    print("+---- End: NpcTreeGossipMenuHandler.OnGossip(...)") -- for debug only
end

--[[
绑定如下事件:

- 将 NpcTreeGossipMenuHandler.OnGossip 方法跟 GOSSIP_EVENT_ON_HELLO 和 GOSSIP_EVENT_ON_SELECT
  事件绑定, 用于处理玩家跟 NPC 对话以及处理玩家点击 gossip 菜单中的 option 的事件.
--]]
function creature_gossip_utils.NpcTreeGossipMenuHandler:RegisterEvents()
    -- See: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
    local CreatureGossipOnGossipHandler = self:BindMethod("OnGossip")
    RegisterCreatureGossipEvent(
            self.creature_template_entry,
            GOSSIP_EVENT_ON_HELLO,
            CreatureGossipOnGossipHandler
    )
    RegisterCreatureGossipEvent(
            self.creature_template_entry,
            GOSSIP_EVENT_ON_SELECT,
            CreatureGossipOnGossipHandler
    )
end

return creature_gossip_utils
