--[[
这个脚本是用于演示如何创建一个 NPC, 跟他对话就能打开一个商店列表, 然后选择进入哪个商店购买物品.
--]]

local GOSSIP_EVENT_ON_HELLO = 1
local GOSSIP_EVENT_ON_SELECT = 2

-- 在 world.creature_template 表中的 npcflag 字段需要是 129 (1 表示是 gossip, 128 表示是 vendor)
local MULTI_VENDOR_NPC_ID = 16781
-- 下面两个 vendor id 是 world.npc_vendor 表中的 entry 字段, 对应着两个不同的商店.
local VENDOR_ID_1 = 54 -- insert your vendor id from npc_vendor table here!
local VENDOR_ID_2 = 66 -- insert another vendor id from npc_vendor table here!

local NPC_TEXT_ID_1 = 1 -- Greetings, $n
local EMPTY_SENDER = 0 -- 用于标识没有 sender 的情况
local GOSSIP_COMPLETE_EVENT = 100
local GOSSIP_ICON_VENDOR = 1 -- Brown bag
local GOSSIP_ICON_TALK = 7 -- White chat bubble with black dots (...)

local function MultiVendorOnGossipHello(event, player, creature)
    --player:GossipClearMenu()
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
    player:GossipMenuAddItem(
        GOSSIP_ICON_VENDOR,
        string.format("vendor %s", VENDOR_ID_1),
        EMPTY_SENDER,
        VENDOR_ID_1
    )
    player:GossipMenuAddItem(
        GOSSIP_ICON_VENDOR,
        string.format("vendor %s", VENDOR_ID_2),
        EMPTY_SENDER,
        VENDOR_ID_2
    )
    player:GossipMenuAddItem(GOSSIP_ICON_TALK, "Close", EMPTY_SENDER, GOSSIP_COMPLETE_EVENT)
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
    player:GossipSendMenu(NPC_TEXT_ID_1, creature) -- menu sender is a creature, so we don't need menu_id
end

local function MultiVendorOnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    if (intid == VENDOR_ID_1) then
        print(string.format("vendor %s", VENDOR_ID_1))
        player:SendListInventory(creature, VENDOR_ID_1)
    elseif (intid == VENDOR_ID_2) then
        print(string.format("vendor %s", VENDOR_ID_2))
        player:SendListInventory(creature, VENDOR_ID_2)
    elseif (intid == GOSSIP_COMPLETE_EVENT) then
        player:GossipComplete()
    end
end

--[[
下面是 RegisterCreatureGossipEvent 的 event code
See: https://www.azerothcore.org/pages/eluna/Global/RegisterCreatureGossipEvent.html
--]]
RegisterCreatureGossipEvent(MULTI_VENDOR_NPC_ID, GOSSIP_EVENT_ON_HELLO, MultiVendorOnGossipHello)
RegisterCreatureGossipEvent(MULTI_VENDOR_NPC_ID, GOSSIP_EVENT_ON_SELECT, MultiVendorOnGossipSelect)