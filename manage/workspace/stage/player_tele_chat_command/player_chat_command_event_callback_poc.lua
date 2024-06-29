--[[
这个脚本用于让演示如何一个让玩家在聊天框输入特定命令后, 触发一个 gossip 菜单. 然后玩家点击
这些菜单上的按钮后, 运行一些逻辑.

在这个例子中我们 #tele 命令来打开传送菜单. 在这个例子中我没有实现传送功能, 而是重点演示这些
event 的 callback 函数的参数.

注意, 我们有几个 player_tele_chat_command 开头的 lua, 它们是同一个脚本在开发过程中的多个
中间版本, 最终只能有一个上传到服务器上. 请确保同一时间只有一个版本的脚本被放到了 lua_scripts 中.
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

--[[
下面是所有跟业务逻辑有关的常量.
--]]
local NPC_TEXT_ID_1 = 1 -- Greetings, $n
local PLAYER_GOSSIP_MENU_ID = 21 -- A menu ID for test
local EMPTY_SENDER = 0 -- 用于标识没有 sender 的情况
local CHAT_COMMAND_TELEPORT = "#tele" -- 玩家在聊天框输入的消息如果是这个, 那么就会触发传送菜单

--[[
这是我们所有跟 teleport 相关的逻辑的 namespace table. 它类似于面向对象中的类一样, 有属性也有方法.

例如后面的 PlayerChatCommandTeleport.OnGossip() 就是一个方法.
--]]
local PlayerChatCommandTeleport = {}

--[[
--------------------------------------------------------------------------------
Event Handler Functions
--------------------------------------------------------------------------------
--]]
function PlayerChatCommandTeleport.OnGossip(
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
    Player:GossipSendMenu() 方法在 PlayerChatCommandTeleport.OnChat() 中手动用代码
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
    print("Enter: PlayerChatCommandTeleport.OnTalk(...)")
    --[[
    打印出 callback 参数的值
    --]]
    print(string.format("event = %s", event))
    print(string.format("player = %s", player))
    print(string.format("object = %s", object))
    print(string.format("sender = %s", sender))
    print(string.format("intid = %d", intid))
    if event == GOSSIP_EVENT_ON_SELECT then
        -- 打印一条消息并关闭 gossip 菜单
        player:SendNotification(string.format("Teleport to gossip item %d", intid))
        player:GossipComplete()
    end
    print("Exit: PlayerChatCommandTeleport.OnTalk(...)")
end

function PlayerChatCommandTeleport.OnChat(event, player, msg, _, lang)
    --[[
    Global:RegisterPlayerEvent@PLAYER_EVENT_ON_CHAT 的参数列表:

    :param event:
    :param player:
    :param msg: 玩家在聊天框输入的消息
    :param Type:
    :param lang: 语种

    See https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
    --]]
    print("Enter: PlayerChatCommandTeleport.OnChat(...)")
    print(string.format("event = %s", event))
    print(string.format("player = %s", player))
    print(string.format("msg = %s", msg))
    print(string.format("lang = %s", lang))
    if (msg == CHAT_COMMAND_TELEPORT) then
        player:SendNotification("Teleport Chat Command Works")

        -- 首先清空已有的 gossip menu, 确保每次玩家输入 #tele 命令时菜单都是新的.
        player:GossipClearMenu()

        --[[
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

        --{name = "达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0},
        --{name = "达拉然 公共旅馆", mapid = 571, x = 5848.9, y = 636.3, z = 647.5, o = 0},
        player:GossipMenuAddItem(GOSSIP_ICON_TAXI, "达拉然 飞行管理员", EMPTY_SENDER, 100)
        player:GossipMenuAddItem(GOSSIP_ICON_TAXI, "达拉然 公共旅馆", EMPTY_SENDER, 200)

        --[[
         Player:GossipSendMenu 方法可以用来发送菜单给玩家. 它的参数列表如下:

        :type npc_text: number
        :param npc_text: Entry ID of a header text in npc_text database table, common default is 100.
            Valid numbers: integers from 0 to 4,294,967,295.
        :type sender: Object
        :param sender: Object acting as the source of the sent gossip menu.
            通常用于识别谁触发了这个 gossip 选项, 我们这里不需要区分, 所以永远传 0.
        :type menu_id: number
        :param menu_id: If sender is a Player then menu_id is mandatory.
            Valid numbers: integers from 0 to 4,294,967,295.

        See: https://www.azerothcore.org/pages/eluna/Player/GossipSendMenu.html
        --]]
        player:GossipSendMenu(NPC_TEXT_ID_1, player, PLAYER_GOSSIP_MENU_ID)
    end
    print("Exit: PlayerChatCommandTeleport.OnChat(...)")
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
RegisterPlayerEvent(PLAYER_EVENT_ON_CHAT, PlayerChatCommandTeleport.OnChat)

--[[
下面是 RegisterPlayerGossipEvent 的 event code
See: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerGossipEvent.html
--]]
RegisterPlayerGossipEvent(
    PLAYER_GOSSIP_MENU_ID,
    GOSSIP_EVENT_ON_SELECT,
    PlayerChatCommandTeleport.OnGossip
)

print("========== player_tele_chat_command.lua is ready to use ==========")
