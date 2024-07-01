--[[
这个库提供了一些跟 gossip menu 有关的辅助函数.
--]]

local record_lookup_utils = require("record_lookup_utils")

local gossip_menu_utils = {}

gossip_menu_utils.NO_PARENT_ID = 0
gossip_menu_utils.NO_SENDER_ID = 0
gossip_menu_utils.NO_GOSSIP_MENU_ID = 21
gossip_menu_utils.DEFAULT_NPC_TEXT_ID = 1 -- Greetings, $n

--[[
**GossipOption 对象**

一个 GossipOption 对象代表着一个 Gossip Menu 上可点击的选项. 这个元素可以是 item 或者是 menu.

- item 是点击后就立刻退出菜单并执行某个操作的选项. 例如点击后打开一个商店界面, 或者将玩家传送到某个地方.
- menu 是点击后会打开一个新的菜单的选项. 例如你让玩家选择传送到哪个地方, 主菜单上有东部王国的选项,
    点击后会出现东部王国的所有地图. 这个 "东部王国" 的选项就是一个 menu. 它的原理是每个 menu
    选项会带一个 id, 点击后会根据这个 id 来查找所有的子菜单选项. 另外, 如果点击后会返回上一级菜单
    或是跳转到其他菜单的选项本质上也是 menu, 因为它的原理也是带一个 id, 只不过这个 id 是它上一级
    菜单的 id, 点击后会根据这个 id 来查找所有上一级菜单的选项.
--]]

---@class GossipOptionType
---@field id number:
---@field name string:
---@field type string:
---@field icon number:
---@field parent number:
---@field data? table:
---@field back_to? number:

---@class ItemGossipOptionType
---@field id number:
---@field name string:
---@field type string:
---@field icon number:
---@field parent number:
---@field data table:

---@class MenuGossipOptionType
---@field id number:
---@field name string:
---@field type string:
---@field icon number:
---@field parent number:

---@class BackGossipOptionType
---@field id number:
---@field name string:
---@field type string:
---@field icon number:
---@field parent number:
---@field back_to number:


--[[
Player:GossipMenuAddItem 是一个给 Player 当前的 gossip menu 添加一个 item 的方法.
下面是它的参数列表:

Ref: https://www.azerothcore.org/pages/eluna/Player/GossipMenuAddItem.html
--]]
---@class GossipMenuItemType
---@field icon number:
---@field msg string:
---@field sender number: 表示这个 gossip menu 的发送者. 注意这是一个 number, 如果发送者是
-----  Creature 或是 Player, 这个值应该是它们的 GUID. 但是如果我们不需要知道 sender 是谁,
-----  传 gossip_menu_utils.NO_SENDER_ID 既可. 这个可以跟实际触发 gossip 的 Object 不一定.
-----  例如你是因为与 Creature 对话而触发 gossip, 但将 sender 设置为一个 Player 也是可以的.
-----  eluna 框架本身不会用这个值做任何逻辑, 而只是在后续的 event 中带上这个变量, 以便我们开发者
-----  可以根据这个值来做一些逻辑.
---@field intid number: 这个 gossip menu item (也是 gossip option) 的唯一 id.
---@field code? boolean @ default: false
---@field popup? number @ default: nil
---@field money? number @ default: 0


--[[
构建一个即将发送给 Player 的 GossipMenu 菜单所需的 item 的数据. 它会根据 parentGossipOptionDataId
来查找所有需要展示的 GossipOption, 并将其转化为 GossipMenuItem. 之所以这个函数返回的是
数据而不是直接用 Player:GossipMenuAddItem 和 Player:GossipSendMenu 把菜单发出去是因为
这样更方便进行测试.
--]]
---@param gossipOptionList GossipOptionType[]: 一个包含所有 GossipOption 的列表
---@param gossipOptionDict table<number, GossipOptionType>: 一个 id -> GossipOption 的字典
---@param parentGossipOptionDataId number: 父菜单的 id, 如果是最顶层菜单,
---  则传 gossip_menu_utils.NO_PARENT_ID 的值
---@param sender number: 表示这个 gossip menu 的发送者. 注意这是一个 number, 如果发送者是
---  Creature 或是 Player, 这个值应该是它们的 GUID. 但是如果我们不需要知道 sender 是谁,
---  传 gossip_menu_utils.NO_SENDER_ID 既可. 这个可以跟实际触发 gossip 的 Object 不一定.
---  例如你是因为与 Creature 对话而触发 gossip, 但将 sender 设置为一个 Player 也是可以的.
---  eluna 框架本身不会用这个值做任何逻辑, 而只是在后续的 event 中带上这个变量, 以便我们开发者
---  可以根据这个值来做一些逻辑.
---@return GossipMenuItemType[]:
function gossip_menu_utils.BuildGossipMenuItemList(
        gossipOptionList,
        gossipOptionDict,
        parentGossipOptionId,
        sender
)
    --[[
    这个函数会是我们用来构建菜单的自定义函数.
    --]]
    print("----- Start: gossip_menu_utils.BuildGossipMenuItemList(...)") -- for debug only
    print(string.format("  gossipOptionList = %s", gossipOptionList))
    print(string.format("  gossipOptionDict = %s", gossipOptionDict))
    print(string.format("  parentGossipOptionId = %s", parentGossipOptionId))
    print(string.format("  sender = %s", sender))
    if sender == nil then
        sender = gossip_menu_utils.NO_SENDER_ID
    end

    local gossipMenuItemList = {}

    local filteredGossipOptionList = record_lookup_utils.FilterByKeyValue(
            gossipOptionList,
            "parent",
            parentGossipOptionId
    )
    for _, gossipOption in ipairs(filteredGossipOptionList) do
        print(string.format("  Found gossipOption.name = %s", gossipOption.name)) -- for debug only
        gossipMenuItem = {
            icon = gossipOption.icon,
            msg = gossipOption.name,
            sender = sender,
            intid = gossipOption.id
        }
        table.insert(gossipMenuItemList, gossipMenuItem)
    end
    --[[
    注: 曾经这里有一段判断 parentGossipOptionId 是不是 0 的逻辑. 如果不是 0, 说明这是一个
    子菜单, 我们会自动添加一个返回上一级菜单, 和一个返回主菜单的选项. 现在我们不再需要这个逻辑了,
    我们在用 Python 准备 gossipOptionList 数据的时候就包含了这个数据了, 无需再自动生成了.
    等于是我们把这一部分的逻辑从 Lua 移动到了 Python (因为 Python 更适合处理这种数据的逻辑).
    --]]
    print("----- End: gossip_menu_utils.BuildGossipMenuItemList(...)") -- for debug only
    return gossipMenuItemList
end

--[[
将 function gossip_menu_utils.BuildGossipMenuItemList() 返回的数据真真正正的以一个
gossip menu 的形式发给 player.
--]]
---@param player Player,
---@param gossipMenuItemList GossipMenuItemType[],
---@param sender Object, 表示这个 gossip menu 的发送者. 一般是一个 Creature, Player
---  这个跟实际触发 gossip 的 Object 可以不一样. 如果你是跟 Creature 对话而触发 gossip,
---  那么一般就传这个 Creature 对象. 而如果你是用聊天框输入 chat 命令来触发, 那么就传
---  一个 Player 对象.
---@param npc_text_id number, 这是 acore_world.npc_text 表中的 id, 用于获取对话文本
--  详情请参考 https://www.azerothcore.org/wiki/npc_text
---@param menu_id number, 这是 acore_world.gossip_menu 表中的 id, 用于获取这个 menu 里
---  有哪些 option. 如果你没有用 Player:GossipMenuAddItem() 方法添加 option,
---  那么你可以用这个 menu_id 从数据库中获得 option. 而如果你用 Player:GossipMenuAddItem()
---  自己创建了这个 menu 的所有 option, 那么你可以传 gossip_menu_utils.NO_GOSSIP_MENU_ID
-- 详情请参考 https://www.azerothcore.org/wiki/gossip_menu
function gossip_menu_utils.SendGossipMenu(
        player,
        gossipMenuItemList,
        sender,
        npc_text_id,
        menu_id
)
    print("----- Start: gossip_menu_utils.SendGossipMenu(...)") -- for debug only
    print("add gossipMenuItem to gossip menu") -- for debug only
    for _, gossipMenuItem in ipairs(gossipMenuItemList) do
        print(string.format("add gossipMenuItem %s", gossipMenuItem.msg)) -- for debug only
        player:GossipMenuAddItem(
                gossipMenuItem.icon,
                gossipMenuItem.msg,
                gossipMenuItem.sender,
                gossipMenuItem.intid
        )
    end
    -- see: https://www.azerothcore.org/pages/eluna/Player/GossipSendMenu.html
    -- if the sender is a Player, then menu_id is mandatory
    print("send gossip menu to player")
    player:GossipSendMenu(
            npc_text_id,
            sender,
            menu_id
    )
    print("----- End: gossip_menu_utils.SendGossipMenu(...)") -- for debug only
end

return gossip_menu_utils
