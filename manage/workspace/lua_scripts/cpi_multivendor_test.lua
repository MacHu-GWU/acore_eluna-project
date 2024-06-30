--[[
这个脚本用于让玩家通过跟特定 NPC 对话, 在层级菜单中选择要购买哪一类型的物品, 然后点击
对话选项打开购买物品的菜单.

注: 如果你需要创建一个类似的功能, 你可以复制这个 jinja2 脚本, 然后替换下面几个 variable.
里如果你要做一个能将玩家传送到指定地点的 NPC, 你的新模块叫做
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

- RegisterCreatureGossipEvent: https://www.azerothcore.org/pages/eluna/Global/RegisterCreatureGossipEvent.html
--]]
local GOSSIP_EVENT_ON_HELLO = 1
local GOSSIP_EVENT_ON_SELECT = 2

--[[
下面是所有跟业务逻辑有关的常量.
--]]
local NPC_TEXT_ID_1 = 1 -- Greetings, $n
local CPI_VENDOR_ENTRY = 5005001 -- 这个 NPC flag 需要是 129
local EMPTY_SENDER = 0 -- 用于标识没有 sender 的情况
local ROOT_CHOICE_DATA_PARENT_ID = 0 -- 如果一个菜单选项没有 parent, 那么它的 parent 属性的值就是这个

--[[
下面是所有 ICON 代码的枚举. 你可以在 "OptionIcon" 一节中看到所有图标的说明.
See: https://www.azerothcore.org/wiki/gossip_menu_option
--]]
local GOSSIP_ICON_TALK = 7

--[[
这是我们所有跟业务逻辑相关的 namespace table. 它类似于面向对象中的类一样, 有属性也有方法.

例如后面的 CpiMultiVendor.OnGossip() 就是一个方法.
--]]
local CpiMultiVendor = {}

--[[
CHOICE_DATA_MAPPER

这个变量是最终展现给玩家的菜单的数据容器. 它是类似于一个 Python 字典的结构. 其中 key 是
choiceData 的唯一 id, value 是 choiceData 本身.

{
    1: { id = 1, name = "...", is_menu = ..., icon = ..., parent = ..., data = { npc_id = ... } },
    2: { id = 1, name = "...", is_menu = ..., icon = ..., parent = ..., data = { npc_id = ... } },
    ...
}
--]]
CpiMultiVendor.CHOICE_DATA_MAPPER = {
    [370001] = { id = 370001, name = "武器", is_menu = true, icon = 0, parent = 0 },
    [370002] = { id = 370002, name = "双手剑", is_menu = true, icon = 0, parent = 370001 },
    [370003] = { id = 370003, name = "双手剑: 200 - 218", is_menu = false, icon = 1, parent = 370002, data = { npc_id = 500068 } },
    [370004] = { id = 370004, name = "双手剑: 219 - 244", is_menu = false, icon = 1, parent = 370002, data = { npc_id = 500069 } },
    [370005] = { id = 370005, name = "双手剑: 245 - 263", is_menu = false, icon = 1, parent = 370002, data = { npc_id = 500070 } },
    [370006] = { id = 370006, name = "双手剑: 264 - 284", is_menu = false, icon = 1, parent = 370002, data = { npc_id = 500071 } },
    [370007] = { id = 370007, name = "双手剑: 制造业成品", is_menu = false, icon = 1, parent = 370002, data = { npc_id = 500063 } },
    [370008] = { id = 370008, name = "单手剑", is_menu = true, icon = 0, parent = 370001 },
    [370009] = { id = 370009, name = "单手剑: 200 - 218", is_menu = false, icon = 1, parent = 370008, data = { npc_id = 500072 } },
    [370010] = { id = 370010, name = "单手剑: 219 - 244", is_menu = false, icon = 1, parent = 370008, data = { npc_id = 500073 } },
    [370011] = { id = 370011, name = "单手剑: 245 - 263", is_menu = false, icon = 1, parent = 370008, data = { npc_id = 500074 } },
    [370012] = { id = 370012, name = "单手剑: 264 - 284", is_menu = false, icon = 1, parent = 370008, data = { npc_id = 500075 } },
    [370013] = { id = 370013, name = "单手剑: 制造业成品", is_menu = false, icon = 1, parent = 370008, data = { npc_id = 500059 } },
    [370014] = { id = 370014, name = "双手斧", is_menu = true, icon = 0, parent = 370001 },
    [370015] = { id = 370015, name = "双手斧: 200 - 218", is_menu = false, icon = 1, parent = 370014, data = { npc_id = 500088 } },
    [370016] = { id = 370016, name = "双手斧: 219 - 244", is_menu = false, icon = 1, parent = 370014, data = { npc_id = 500089 } },
    [370017] = { id = 370017, name = "双手斧: 245 - 263", is_menu = false, icon = 1, parent = 370014, data = { npc_id = 500090 } },
    [370018] = { id = 370018, name = "双手斧: 264 - 284", is_menu = false, icon = 1, parent = 370014, data = { npc_id = 500091 } },
    [370019] = { id = 370019, name = "双手斧: 制造业成品", is_menu = false, icon = 1, parent = 370014, data = { npc_id = 500058 } },
    [370020] = { id = 370020, name = "单手斧", is_menu = true, icon = 0, parent = 370001 },
    [370021] = { id = 370021, name = "单手斧: 200 - 218", is_menu = false, icon = 1, parent = 370020, data = { npc_id = 500080 } },
    [370022] = { id = 370022, name = "单手斧: 219 - 244", is_menu = false, icon = 1, parent = 370020, data = { npc_id = 500081 } },
    [370023] = { id = 370023, name = "单手斧: 245 - 263", is_menu = false, icon = 1, parent = 370020, data = { npc_id = 500082 } },
    [370024] = { id = 370024, name = "单手斧: 264 - 284", is_menu = false, icon = 1, parent = 370020, data = { npc_id = 500083 } },
    [370025] = { id = 370025, name = "单手斧: 制造业成品", is_menu = false, icon = 1, parent = 370020, data = { npc_id = 500064 } },
    [370026] = { id = 370026, name = "双手锤", is_menu = true, icon = 0, parent = 370001 },
    [370027] = { id = 370027, name = "双手锤: 200 - 218", is_menu = false, icon = 1, parent = 370026, data = { npc_id = 500104 } },
    [370028] = { id = 370028, name = "双手锤: 219 - 244", is_menu = false, icon = 1, parent = 370026, data = { npc_id = 500105 } },
    [370029] = { id = 370029, name = "双手锤: 245 - 263", is_menu = false, icon = 1, parent = 370026, data = { npc_id = 500106 } },
    [370030] = { id = 370030, name = "双手锤: 264 - 284", is_menu = false, icon = 1, parent = 370026, data = { npc_id = 500107 } },
    [370031] = { id = 370031, name = "双手锤: 制造业成品", is_menu = false, icon = 1, parent = 370026, data = { npc_id = 500065 } },
    [370032] = { id = 370032, name = "单手锤", is_menu = true, icon = 0, parent = 370001 },
    [370033] = { id = 370033, name = "单手锤: 200 - 218", is_menu = false, icon = 1, parent = 370032, data = { npc_id = 500076 } },
    [370034] = { id = 370034, name = "单手锤: 219 - 244", is_menu = false, icon = 1, parent = 370032, data = { npc_id = 500077 } },
    [370035] = { id = 370035, name = "单手锤: 245 - 263", is_menu = false, icon = 1, parent = 370032, data = { npc_id = 500078 } },
    [370036] = { id = 370036, name = "单手锤: 264 - 284", is_menu = false, icon = 1, parent = 370032, data = { npc_id = 500079 } },
    [370037] = { id = 370037, name = "单手锤: 制造业成品", is_menu = false, icon = 1, parent = 370032, data = { npc_id = 500061 } },
    [370038] = { id = 370038, name = "长柄武器", is_menu = true, icon = 0, parent = 370001 },
    [370039] = { id = 370039, name = "长柄武器: 200 - 218", is_menu = false, icon = 1, parent = 370038, data = { npc_id = 500108 } },
    [370040] = { id = 370040, name = "长柄武器: 219 - 244", is_menu = false, icon = 1, parent = 370038, data = { npc_id = 500109 } },
    [370041] = { id = 370041, name = "长柄武器: 245 - 263", is_menu = false, icon = 1, parent = 370038, data = { npc_id = 500110 } },
    [370042] = { id = 370042, name = "长柄武器: 264 - 284", is_menu = false, icon = 1, parent = 370038, data = { npc_id = 500111 } },
    [370043] = { id = 370043, name = "法杖", is_menu = true, icon = 0, parent = 370001 },
    [370044] = { id = 370044, name = "法杖: 200 - 218", is_menu = false, icon = 1, parent = 370043, data = { npc_id = 500084 } },
    [370045] = { id = 370045, name = "法杖: 219 - 244", is_menu = false, icon = 1, parent = 370043, data = { npc_id = 500085 } },
    [370046] = { id = 370046, name = "法杖: 245 - 263", is_menu = false, icon = 1, parent = 370043, data = { npc_id = 500086 } },
    [370047] = { id = 370047, name = "法杖: 264 - 284", is_menu = false, icon = 1, parent = 370043, data = { npc_id = 500087 } },
    [370048] = { id = 370048, name = "魔杖", is_menu = true, icon = 0, parent = 370001 },
    [370049] = { id = 370049, name = "魔杖: 200 - 218", is_menu = false, icon = 1, parent = 370048, data = { npc_id = 500112 } },
    [370050] = { id = 370050, name = "魔杖: 219 - 244", is_menu = false, icon = 1, parent = 370048, data = { npc_id = 500113 } },
    [370051] = { id = 370051, name = "魔杖: 245 - 263", is_menu = false, icon = 1, parent = 370048, data = { npc_id = 500114 } },
    [370052] = { id = 370052, name = "魔杖: 264 - 284", is_menu = false, icon = 1, parent = 370048, data = { npc_id = 500115 } },
    [370053] = { id = 370053, name = "魔杖: 制造业成品", is_menu = false, icon = 1, parent = 370048, data = { npc_id = 500066 } },
    [370054] = { id = 370054, name = "匕首", is_menu = true, icon = 0, parent = 370001 },
    [370055] = { id = 370055, name = "匕首: 200 - 218", is_menu = false, icon = 1, parent = 370054, data = { npc_id = 500096 } },
    [370056] = { id = 370056, name = "匕首: 219 - 244", is_menu = false, icon = 1, parent = 370054, data = { npc_id = 500097 } },
    [370057] = { id = 370057, name = "匕首: 245 - 263", is_menu = false, icon = 1, parent = 370054, data = { npc_id = 500098 } },
    [370058] = { id = 370058, name = "匕首: 264 - 284", is_menu = false, icon = 1, parent = 370054, data = { npc_id = 500099 } },
    [370059] = { id = 370059, name = "匕首: 制造业成品", is_menu = false, icon = 1, parent = 370054, data = { npc_id = 500060 } },
    [370060] = { id = 370060, name = "拳套", is_menu = true, icon = 0, parent = 370001 },
    [370061] = { id = 370061, name = "拳套: 200 - 218", is_menu = false, icon = 1, parent = 370060, data = { npc_id = 500116 } },
    [370062] = { id = 370062, name = "拳套: 219 - 244", is_menu = false, icon = 1, parent = 370060, data = { npc_id = 500117 } },
    [370063] = { id = 370063, name = "拳套: 245 - 263", is_menu = false, icon = 1, parent = 370060, data = { npc_id = 500118 } },
    [370064] = { id = 370064, name = "拳套: 264 - 284", is_menu = false, icon = 1, parent = 370060, data = { npc_id = 500119 } },
    [370065] = { id = 370065, name = "弓", is_menu = true, icon = 0, parent = 370001 },
    [370066] = { id = 370066, name = "弓: 200 - 218", is_menu = false, icon = 1, parent = 370065, data = { npc_id = 500100 } },
    [370067] = { id = 370067, name = "弓: 219 - 244", is_menu = false, icon = 1, parent = 370065, data = { npc_id = 500101 } },
    [370068] = { id = 370068, name = "弓: 245 - 263", is_menu = false, icon = 1, parent = 370065, data = { npc_id = 500102 } },
    [370069] = { id = 370069, name = "弓: 264 - 284", is_menu = false, icon = 1, parent = 370065, data = { npc_id = 500103 } },
    [370070] = { id = 370070, name = "弩", is_menu = true, icon = 0, parent = 370001 },
    [370071] = { id = 370071, name = "弩: 200 - 218", is_menu = false, icon = 1, parent = 370070, data = { npc_id = 500120 } },
    [370072] = { id = 370072, name = "弩: 219 - 244", is_menu = false, icon = 1, parent = 370070, data = { npc_id = 500121 } },
    [370073] = { id = 370073, name = "弩: 245 - 263", is_menu = false, icon = 1, parent = 370070, data = { npc_id = 500122 } },
    [370074] = { id = 370074, name = "弩: 264 - 284", is_menu = false, icon = 1, parent = 370070, data = { npc_id = 500123 } },
    [370075] = { id = 370075, name = "枪", is_menu = true, icon = 0, parent = 370001 },
    [370076] = { id = 370076, name = "枪: 200 - 218", is_menu = false, icon = 1, parent = 370075, data = { npc_id = 500092 } },
    [370077] = { id = 370077, name = "枪: 219 - 244", is_menu = false, icon = 1, parent = 370075, data = { npc_id = 500093 } },
    [370078] = { id = 370078, name = "枪: 245 - 263", is_menu = false, icon = 1, parent = 370075, data = { npc_id = 500094 } },
    [370079] = { id = 370079, name = "枪: 264 - 284", is_menu = false, icon = 1, parent = 370075, data = { npc_id = 500095 } },
    [370080] = { id = 370080, name = "枪: 制造业成品", is_menu = false, icon = 1, parent = 370075, data = { npc_id = 500057 } },
    [370081] = { id = 370081, name = "投掷武器", is_menu = true, icon = 0, parent = 370001 },
    [370082] = { id = 370082, name = "投掷武器: 200 - 218", is_menu = false, icon = 1, parent = 370081, data = { npc_id = 500124 } },
    [370083] = { id = 370083, name = "投掷武器: 219 - 244", is_menu = false, icon = 1, parent = 370081, data = { npc_id = 500125 } },
    [370084] = { id = 370084, name = "投掷武器: 245 - 263", is_menu = false, icon = 1, parent = 370081, data = { npc_id = 500126 } },
    [370085] = { id = 370085, name = "投掷武器: 264 - 284", is_menu = false, icon = 1, parent = 370081, data = { npc_id = 500127 } },
    [370086] = { id = 370086, name = "投掷武器: 制造业成品", is_menu = false, icon = 1, parent = 370081, data = { npc_id = 500062 } },
    [370087] = { id = 370087, name = "鱼杆", is_menu = true, icon = 0, parent = 370001 },
    [370088] = { id = 370088, name = "鱼杆: 200 - 218", is_menu = false, icon = 1, parent = 370087, data = { npc_id = 500128 } },
    [370089] = { id = 370089, name = "鱼杆: 219 - 244", is_menu = false, icon = 1, parent = 370087, data = { npc_id = 500129 } },
    [370090] = { id = 370090, name = "鱼杆: 245 - 263", is_menu = false, icon = 1, parent = 370087, data = { npc_id = 500130 } },
    [370091] = { id = 370091, name = "鱼杆: 264 - 284", is_menu = false, icon = 1, parent = 370087, data = { npc_id = 500131 } },
    [370092] = { id = 370092, name = "护甲", is_menu = true, icon = 0, parent = 0 },
    [370093] = { id = 370093, name = "板甲", is_menu = true, icon = 0, parent = 370092 },
    [370094] = { id = 370094, name = "头部", is_menu = true, icon = 0, parent = 370093 },
    [370095] = { id = 370095, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 370094, data = { npc_id = 500276 } },
    [370096] = { id = 370096, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 370094, data = { npc_id = 500277 } },
    [370097] = { id = 370097, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 370094, data = { npc_id = 500278 } },
    [370098] = { id = 370098, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 370094, data = { npc_id = 500279 } },
    [370099] = { id = 370099, name = "肩部", is_menu = true, icon = 0, parent = 370093 },
    [370100] = { id = 370100, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 370099, data = { npc_id = 500288 } },
    [370101] = { id = 370101, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 370099, data = { npc_id = 500289 } },
    [370102] = { id = 370102, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 370099, data = { npc_id = 500290 } },
    [370103] = { id = 370103, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 370099, data = { npc_id = 500291 } },
    [370104] = { id = 370104, name = "胸部", is_menu = true, icon = 0, parent = 370093 },
    [370105] = { id = 370105, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 370104, data = { npc_id = 500280 } },
    [370106] = { id = 370106, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 370104, data = { npc_id = 500281 } },
    [370107] = { id = 370107, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 370104, data = { npc_id = 500282 } },
    [370108] = { id = 370108, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 370104, data = { npc_id = 500283 } },
    [370109] = { id = 370109, name = "手腕", is_menu = true, icon = 0, parent = 370093 },
    [370110] = { id = 370110, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 370109, data = { npc_id = 500296 } },
    [370111] = { id = 370111, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 370109, data = { npc_id = 500297 } },
    [370112] = { id = 370112, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 370109, data = { npc_id = 500298 } },
    [370113] = { id = 370113, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 370109, data = { npc_id = 500299 } },
    [370114] = { id = 370114, name = "手部", is_menu = true, icon = 0, parent = 370093 },
    [370115] = { id = 370115, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 370114, data = { npc_id = 500272 } },
    [370116] = { id = 370116, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 370114, data = { npc_id = 500273 } },
    [370117] = { id = 370117, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 370114, data = { npc_id = 500274 } },
    [370118] = { id = 370118, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 370114, data = { npc_id = 500275 } },
    [370119] = { id = 370119, name = "腰部", is_menu = true, icon = 0, parent = 370093 },
    [370120] = { id = 370120, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 370119, data = { npc_id = 500300 } },
    [370121] = { id = 370121, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 370119, data = { npc_id = 500301 } },
    [370122] = { id = 370122, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 370119, data = { npc_id = 500302 } },
    [370123] = { id = 370123, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 370119, data = { npc_id = 500303 } },
    [370124] = { id = 370124, name = "腿部", is_menu = true, icon = 0, parent = 370093 },
    [370125] = { id = 370125, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 370124, data = { npc_id = 500292 } },
    [370126] = { id = 370126, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 370124, data = { npc_id = 500293 } },
    [370127] = { id = 370127, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 370124, data = { npc_id = 500294 } },
    [370128] = { id = 370128, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 370124, data = { npc_id = 500295 } },
    [370129] = { id = 370129, name = "脚部", is_menu = true, icon = 0, parent = 370093 },
    [370130] = { id = 370130, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 370129, data = { npc_id = 500284 } },
    [370131] = { id = 370131, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 370129, data = { npc_id = 500285 } },
    [370132] = { id = 370132, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 370129, data = { npc_id = 500286 } },
    [370133] = { id = 370133, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 370129, data = { npc_id = 500287 } },
    [370134] = { id = 370134, name = "板甲: 制造业成品", is_menu = false, icon = 1, parent = 370093, data = { npc_id = 500042 } },
    [370135] = { id = 370135, name = "锁甲", is_menu = true, icon = 0, parent = 370092 },
    [370136] = { id = 370136, name = "头部", is_menu = true, icon = 0, parent = 370135 },
    [370137] = { id = 370137, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 370136, data = { npc_id = 500240 } },
    [370138] = { id = 370138, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 370136, data = { npc_id = 500241 } },
    [370139] = { id = 370139, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 370136, data = { npc_id = 500242 } },
    [370140] = { id = 370140, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 370136, data = { npc_id = 500243 } },
    [370141] = { id = 370141, name = "肩部", is_menu = true, icon = 0, parent = 370135 },
    [370142] = { id = 370142, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 370141, data = { npc_id = 500256 } },
    [370143] = { id = 370143, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 370141, data = { npc_id = 500257 } },
    [370144] = { id = 370144, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 370141, data = { npc_id = 500258 } },
    [370145] = { id = 370145, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 370141, data = { npc_id = 500259 } },
    [370146] = { id = 370146, name = "胸部", is_menu = true, icon = 0, parent = 370135 },
    [370147] = { id = 370147, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 370146, data = { npc_id = 500236 } },
    [370148] = { id = 370148, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 370146, data = { npc_id = 500237 } },
    [370149] = { id = 370149, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 370146, data = { npc_id = 500238 } },
    [370150] = { id = 370150, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 370146, data = { npc_id = 500239 } },
    [370151] = { id = 370151, name = "长袍", is_menu = true, icon = 0, parent = 370135 },
    [370152] = { id = 370152, name = "长袍: 200 - 218", is_menu = false, icon = 1, parent = 370151, data = { npc_id = 500268 } },
    [370153] = { id = 370153, name = "长袍: 219 - 244", is_menu = false, icon = 1, parent = 370151, data = { npc_id = 500269 } },
    [370154] = { id = 370154, name = "长袍: 245 - 263", is_menu = false, icon = 1, parent = 370151, data = { npc_id = 500270 } },
    [370155] = { id = 370155, name = "长袍: 264 - 284", is_menu = false, icon = 1, parent = 370151, data = { npc_id = 500271 } },
    [370156] = { id = 370156, name = "手腕", is_menu = true, icon = 0, parent = 370135 },
    [370157] = { id = 370157, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 370156, data = { npc_id = 500264 } },
    [370158] = { id = 370158, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 370156, data = { npc_id = 500265 } },
    [370159] = { id = 370159, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 370156, data = { npc_id = 500266 } },
    [370160] = { id = 370160, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 370156, data = { npc_id = 500267 } },
    [370161] = { id = 370161, name = "手部", is_menu = true, icon = 0, parent = 370135 },
    [370162] = { id = 370162, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 370161, data = { npc_id = 500248 } },
    [370163] = { id = 370163, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 370161, data = { npc_id = 500249 } },
    [370164] = { id = 370164, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 370161, data = { npc_id = 500250 } },
    [370165] = { id = 370165, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 370161, data = { npc_id = 500251 } },
    [370166] = { id = 370166, name = "腰部", is_menu = true, icon = 0, parent = 370135 },
    [370167] = { id = 370167, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 370166, data = { npc_id = 500260 } },
    [370168] = { id = 370168, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 370166, data = { npc_id = 500261 } },
    [370169] = { id = 370169, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 370166, data = { npc_id = 500262 } },
    [370170] = { id = 370170, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 370166, data = { npc_id = 500263 } },
    [370171] = { id = 370171, name = "腿部", is_menu = true, icon = 0, parent = 370135 },
    [370172] = { id = 370172, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 370171, data = { npc_id = 500244 } },
    [370173] = { id = 370173, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 370171, data = { npc_id = 500245 } },
    [370174] = { id = 370174, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 370171, data = { npc_id = 500246 } },
    [370175] = { id = 370175, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 370171, data = { npc_id = 500247 } },
    [370176] = { id = 370176, name = "脚部", is_menu = true, icon = 0, parent = 370135 },
    [370177] = { id = 370177, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 370176, data = { npc_id = 500252 } },
    [370178] = { id = 370178, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 370176, data = { npc_id = 500253 } },
    [370179] = { id = 370179, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 370176, data = { npc_id = 500254 } },
    [370180] = { id = 370180, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 370176, data = { npc_id = 500255 } },
    [370181] = { id = 370181, name = "锁甲: 制造业成品", is_menu = false, icon = 1, parent = 370135, data = { npc_id = 500040 } },
    [370182] = { id = 370182, name = "皮甲", is_menu = true, icon = 0, parent = 370092 },
    [370183] = { id = 370183, name = "头部", is_menu = true, icon = 0, parent = 370182 },
    [370184] = { id = 370184, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 370183, data = { npc_id = 500184 } },
    [370185] = { id = 370185, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 370183, data = { npc_id = 500185 } },
    [370186] = { id = 370186, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 370183, data = { npc_id = 500186 } },
    [370187] = { id = 370187, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 370183, data = { npc_id = 500187 } },
    [370188] = { id = 370188, name = "肩部", is_menu = true, icon = 0, parent = 370182 },
    [370189] = { id = 370189, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 370188, data = { npc_id = 500180 } },
    [370190] = { id = 370190, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 370188, data = { npc_id = 500181 } },
    [370191] = { id = 370191, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 370188, data = { npc_id = 500182 } },
    [370192] = { id = 370192, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 370188, data = { npc_id = 500183 } },
    [370193] = { id = 370193, name = "胸部", is_menu = true, icon = 0, parent = 370182 },
    [370194] = { id = 370194, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 370193, data = { npc_id = 500164 } },
    [370195] = { id = 370195, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 370193, data = { npc_id = 500165 } },
    [370196] = { id = 370196, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 370193, data = { npc_id = 500166 } },
    [370197] = { id = 370197, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 370193, data = { npc_id = 500167 } },
    [370198] = { id = 370198, name = "长袍", is_menu = true, icon = 0, parent = 370182 },
    [370199] = { id = 370199, name = "长袍: 200 - 218", is_menu = false, icon = 1, parent = 370198, data = { npc_id = 500188 } },
    [370200] = { id = 370200, name = "长袍: 219 - 244", is_menu = false, icon = 1, parent = 370198, data = { npc_id = 500189 } },
    [370201] = { id = 370201, name = "长袍: 245 - 263", is_menu = false, icon = 1, parent = 370198, data = { npc_id = 500190 } },
    [370202] = { id = 370202, name = "长袍: 264 - 284", is_menu = false, icon = 1, parent = 370198, data = { npc_id = 500191 } },
    [370203] = { id = 370203, name = "手腕", is_menu = true, icon = 0, parent = 370182 },
    [370204] = { id = 370204, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 370203, data = { npc_id = 500168 } },
    [370205] = { id = 370205, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 370203, data = { npc_id = 500169 } },
    [370206] = { id = 370206, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 370203, data = { npc_id = 500170 } },
    [370207] = { id = 370207, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 370203, data = { npc_id = 500171 } },
    [370208] = { id = 370208, name = "手部", is_menu = true, icon = 0, parent = 370182 },
    [370209] = { id = 370209, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 370208, data = { npc_id = 500156 } },
    [370210] = { id = 370210, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 370208, data = { npc_id = 500157 } },
    [370211] = { id = 370211, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 370208, data = { npc_id = 500158 } },
    [370212] = { id = 370212, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 370208, data = { npc_id = 500159 } },
    [370213] = { id = 370213, name = "腰部", is_menu = true, icon = 0, parent = 370182 },
    [370214] = { id = 370214, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 370213, data = { npc_id = 500172 } },
    [370215] = { id = 370215, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 370213, data = { npc_id = 500173 } },
    [370216] = { id = 370216, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 370213, data = { npc_id = 500174 } },
    [370217] = { id = 370217, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 370213, data = { npc_id = 500175 } },
    [370218] = { id = 370218, name = "腿部", is_menu = true, icon = 0, parent = 370182 },
    [370219] = { id = 370219, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 370218, data = { npc_id = 500160 } },
    [370220] = { id = 370220, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 370218, data = { npc_id = 500161 } },
    [370221] = { id = 370221, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 370218, data = { npc_id = 500162 } },
    [370222] = { id = 370222, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 370218, data = { npc_id = 500163 } },
    [370223] = { id = 370223, name = "脚部", is_menu = true, icon = 0, parent = 370182 },
    [370224] = { id = 370224, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 370223, data = { npc_id = 500176 } },
    [370225] = { id = 370225, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 370223, data = { npc_id = 500177 } },
    [370226] = { id = 370226, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 370223, data = { npc_id = 500178 } },
    [370227] = { id = 370227, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 370223, data = { npc_id = 500179 } },
    [370228] = { id = 370228, name = "皮甲: 制造业成品", is_menu = false, icon = 1, parent = 370182, data = { npc_id = 500041 } },
    [370229] = { id = 370229, name = "布甲", is_menu = true, icon = 0, parent = 370092 },
    [370230] = { id = 370230, name = "头部", is_menu = true, icon = 0, parent = 370229 },
    [370231] = { id = 370231, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 370230, data = { npc_id = 500196 } },
    [370232] = { id = 370232, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 370230, data = { npc_id = 500197 } },
    [370233] = { id = 370233, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 370230, data = { npc_id = 500198 } },
    [370234] = { id = 370234, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 370230, data = { npc_id = 500199 } },
    [370235] = { id = 370235, name = "肩部", is_menu = true, icon = 0, parent = 370229 },
    [370236] = { id = 370236, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 370235, data = { npc_id = 500216 } },
    [370237] = { id = 370237, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 370235, data = { npc_id = 500217 } },
    [370238] = { id = 370238, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 370235, data = { npc_id = 500218 } },
    [370239] = { id = 370239, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 370235, data = { npc_id = 500219 } },
    [370240] = { id = 370240, name = "长袍", is_menu = true, icon = 0, parent = 370229 },
    [370241] = { id = 370241, name = "长袍: 200 - 218", is_menu = false, icon = 1, parent = 370240, data = { npc_id = 500192 } },
    [370242] = { id = 370242, name = "长袍: 219 - 244", is_menu = false, icon = 1, parent = 370240, data = { npc_id = 500193 } },
    [370243] = { id = 370243, name = "长袍: 245 - 263", is_menu = false, icon = 1, parent = 370240, data = { npc_id = 500194 } },
    [370244] = { id = 370244, name = "长袍: 264 - 284", is_menu = false, icon = 1, parent = 370240, data = { npc_id = 500195 } },
    [370245] = { id = 370245, name = "胸部", is_menu = true, icon = 0, parent = 370229 },
    [370246] = { id = 370246, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 370245, data = { npc_id = 500228 } },
    [370247] = { id = 370247, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 370245, data = { npc_id = 500229 } },
    [370248] = { id = 370248, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 370245, data = { npc_id = 500230 } },
    [370249] = { id = 370249, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 370245, data = { npc_id = 500231 } },
    [370250] = { id = 370250, name = "手腕", is_menu = true, icon = 0, parent = 370229 },
    [370251] = { id = 370251, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 370250, data = { npc_id = 500220 } },
    [370252] = { id = 370252, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 370250, data = { npc_id = 500221 } },
    [370253] = { id = 370253, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 370250, data = { npc_id = 500222 } },
    [370254] = { id = 370254, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 370250, data = { npc_id = 500223 } },
    [370255] = { id = 370255, name = "手部", is_menu = true, icon = 0, parent = 370229 },
    [370256] = { id = 370256, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 370255, data = { npc_id = 500204 } },
    [370257] = { id = 370257, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 370255, data = { npc_id = 500205 } },
    [370258] = { id = 370258, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 370255, data = { npc_id = 500206 } },
    [370259] = { id = 370259, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 370255, data = { npc_id = 500207 } },
    [370260] = { id = 370260, name = "腰部", is_menu = true, icon = 0, parent = 370229 },
    [370261] = { id = 370261, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 370260, data = { npc_id = 500224 } },
    [370262] = { id = 370262, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 370260, data = { npc_id = 500225 } },
    [370263] = { id = 370263, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 370260, data = { npc_id = 500226 } },
    [370264] = { id = 370264, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 370260, data = { npc_id = 500227 } },
    [370265] = { id = 370265, name = "腿部", is_menu = true, icon = 0, parent = 370229 },
    [370266] = { id = 370266, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 370265, data = { npc_id = 500212 } },
    [370267] = { id = 370267, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 370265, data = { npc_id = 500213 } },
    [370268] = { id = 370268, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 370265, data = { npc_id = 500214 } },
    [370269] = { id = 370269, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 370265, data = { npc_id = 500215 } },
    [370270] = { id = 370270, name = "脚部", is_menu = true, icon = 0, parent = 370229 },
    [370271] = { id = 370271, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 370270, data = { npc_id = 500208 } },
    [370272] = { id = 370272, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 370270, data = { npc_id = 500209 } },
    [370273] = { id = 370273, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 370270, data = { npc_id = 500210 } },
    [370274] = { id = 370274, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 370270, data = { npc_id = 500211 } },
    [370275] = { id = 370275, name = "背部", is_menu = true, icon = 0, parent = 370229 },
    [370276] = { id = 370276, name = "背部: 200 - 218", is_menu = false, icon = 1, parent = 370275, data = { npc_id = 500200 } },
    [370277] = { id = 370277, name = "背部: 219 - 244", is_menu = false, icon = 1, parent = 370275, data = { npc_id = 500201 } },
    [370278] = { id = 370278, name = "背部: 245 - 263", is_menu = false, icon = 1, parent = 370275, data = { npc_id = 500202 } },
    [370279] = { id = 370279, name = "背部: 264 - 284", is_menu = false, icon = 1, parent = 370275, data = { npc_id = 500203 } },
    [370280] = { id = 370280, name = "布甲: 制造业成品", is_menu = false, icon = 1, parent = 370229, data = { npc_id = 500044 } },
    [370281] = { id = 370281, name = "其它戒指等", is_menu = true, icon = 0, parent = 370092 },
    [370282] = { id = 370282, name = "颈部", is_menu = true, icon = 0, parent = 370281 },
    [370283] = { id = 370283, name = "颈部: 200 - 218", is_menu = false, icon = 1, parent = 370282, data = { npc_id = 500140 } },
    [370284] = { id = 370284, name = "颈部: 219 - 244", is_menu = false, icon = 1, parent = 370282, data = { npc_id = 500141 } },
    [370285] = { id = 370285, name = "颈部: 245 - 263", is_menu = false, icon = 1, parent = 370282, data = { npc_id = 500142 } },
    [370286] = { id = 370286, name = "颈部: 264 - 284", is_menu = false, icon = 1, parent = 370282, data = { npc_id = 500143 } },
    [370287] = { id = 370287, name = "副手物品", is_menu = true, icon = 0, parent = 370281 },
    [370288] = { id = 370288, name = "副手物品: 200 - 218", is_menu = false, icon = 1, parent = 370287, data = { npc_id = 500144 } },
    [370289] = { id = 370289, name = "副手物品: 219 - 244", is_menu = false, icon = 1, parent = 370287, data = { npc_id = 500145 } },
    [370290] = { id = 370290, name = "副手物品: 245 - 263", is_menu = false, icon = 1, parent = 370287, data = { npc_id = 500146 } },
    [370291] = { id = 370291, name = "副手物品: 264 - 284", is_menu = false, icon = 1, parent = 370287, data = { npc_id = 500147 } },
    [370292] = { id = 370292, name = "手指", is_menu = true, icon = 0, parent = 370281 },
    [370293] = { id = 370293, name = "手指: 200 - 218", is_menu = false, icon = 1, parent = 370292, data = { npc_id = 500136 } },
    [370294] = { id = 370294, name = "手指: 219 - 244", is_menu = false, icon = 1, parent = 370292, data = { npc_id = 500137 } },
    [370295] = { id = 370295, name = "手指: 245 - 263", is_menu = false, icon = 1, parent = 370292, data = { npc_id = 500138 } },
    [370296] = { id = 370296, name = "手指: 264 - 284", is_menu = false, icon = 1, parent = 370292, data = { npc_id = 500139 } },
    [370297] = { id = 370297, name = "饰品", is_menu = true, icon = 0, parent = 370281 },
    [370298] = { id = 370298, name = "饰品: 200 - 218", is_menu = false, icon = 1, parent = 370297, data = { npc_id = 500132 } },
    [370299] = { id = 370299, name = "饰品: 219 - 244", is_menu = false, icon = 1, parent = 370297, data = { npc_id = 500133 } },
    [370300] = { id = 370300, name = "饰品: 245 - 263", is_menu = false, icon = 1, parent = 370297, data = { npc_id = 500134 } },
    [370301] = { id = 370301, name = "饰品: 264 - 284", is_menu = false, icon = 1, parent = 370297, data = { npc_id = 500135 } },
    [370302] = { id = 370302, name = "衬衣", is_menu = true, icon = 0, parent = 370281 },
    [370303] = { id = 370303, name = "衬衣: 200 - 218", is_menu = false, icon = 1, parent = 370302, data = { npc_id = 500152 } },
    [370304] = { id = 370304, name = "衬衣: 219 - 244", is_menu = false, icon = 1, parent = 370302, data = { npc_id = 500153 } },
    [370305] = { id = 370305, name = "衬衣: 245 - 263", is_menu = false, icon = 1, parent = 370302, data = { npc_id = 500154 } },
    [370306] = { id = 370306, name = "衬衣: 264 - 284", is_menu = false, icon = 1, parent = 370302, data = { npc_id = 500155 } },
    [370307] = { id = 370307, name = "徽章", is_menu = true, icon = 0, parent = 370281 },
    [370308] = { id = 370308, name = "徽章: 200 - 218", is_menu = false, icon = 1, parent = 370307, data = { npc_id = 500148 } },
    [370309] = { id = 370309, name = "徽章: 219 - 244", is_menu = false, icon = 1, parent = 370307, data = { npc_id = 500149 } },
    [370310] = { id = 370310, name = "徽章: 245 - 263", is_menu = false, icon = 1, parent = 370307, data = { npc_id = 500150 } },
    [370311] = { id = 370311, name = "徽章: 264 - 284", is_menu = false, icon = 1, parent = 370307, data = { npc_id = 500151 } },
    [370312] = { id = 370312, name = "其它戒指等: 制造业成品", is_menu = false, icon = 1, parent = 370281, data = { npc_id = 500039 } },
    [370313] = { id = 370313, name = "盾牌", is_menu = true, icon = 0, parent = 370092 },
    [370314] = { id = 370314, name = "盾牌", is_menu = true, icon = 0, parent = 370313 },
    [370315] = { id = 370315, name = "盾牌: 200 - 218", is_menu = false, icon = 1, parent = 370314, data = { npc_id = 500232 } },
    [370316] = { id = 370316, name = "盾牌: 219 - 244", is_menu = false, icon = 1, parent = 370314, data = { npc_id = 500233 } },
    [370317] = { id = 370317, name = "盾牌: 245 - 263", is_menu = false, icon = 1, parent = 370314, data = { npc_id = 500234 } },
    [370318] = { id = 370318, name = "盾牌: 264 - 284", is_menu = false, icon = 1, parent = 370314, data = { npc_id = 500235 } },
    [370319] = { id = 370319, name = "盾牌: 制造业成品", is_menu = false, icon = 1, parent = 370313, data = { npc_id = 500043 } },
    [370320] = { id = 370320, name = "图腾圣物圣契符印", is_menu = true, icon = 0, parent = 370092 },
    [370321] = { id = 370321, name = "圣契", is_menu = true, icon = 0, parent = 370320 },
    [370322] = { id = 370322, name = "圣契: 200 - 218", is_menu = false, icon = 1, parent = 370321, data = { npc_id = 500312 } },
    [370323] = { id = 370323, name = "圣契: 219 - 244", is_menu = false, icon = 1, parent = 370321, data = { npc_id = 500313 } },
    [370324] = { id = 370324, name = "圣契: 245 - 263", is_menu = false, icon = 1, parent = 370321, data = { npc_id = 500314 } },
    [370325] = { id = 370325, name = "圣契: 264 - 284", is_menu = false, icon = 1, parent = 370321, data = { npc_id = 500315 } },
    [370326] = { id = 370326, name = "图腾", is_menu = true, icon = 0, parent = 370320 },
    [370327] = { id = 370327, name = "图腾: 200 - 218", is_menu = false, icon = 1, parent = 370326, data = { npc_id = 500304 } },
    [370328] = { id = 370328, name = "图腾: 219 - 244", is_menu = false, icon = 1, parent = 370326, data = { npc_id = 500305 } },
    [370329] = { id = 370329, name = "图腾: 245 - 263", is_menu = false, icon = 1, parent = 370326, data = { npc_id = 500306 } },
    [370330] = { id = 370330, name = "图腾: 264 - 284", is_menu = false, icon = 1, parent = 370326, data = { npc_id = 500307 } },
    [370331] = { id = 370331, name = "神像", is_menu = true, icon = 0, parent = 370320 },
    [370332] = { id = 370332, name = "神像: 200 - 218", is_menu = false, icon = 1, parent = 370331, data = { npc_id = 500308 } },
    [370333] = { id = 370333, name = "神像: 219 - 244", is_menu = false, icon = 1, parent = 370331, data = { npc_id = 500309 } },
    [370334] = { id = 370334, name = "神像: 245 - 263", is_menu = false, icon = 1, parent = 370331, data = { npc_id = 500310 } },
    [370335] = { id = 370335, name = "神像: 264 - 284", is_menu = false, icon = 1, parent = 370331, data = { npc_id = 500311 } },
    [370336] = { id = 370336, name = "魔印", is_menu = true, icon = 0, parent = 370320 },
    [370337] = { id = 370337, name = "魔印: 200 - 218", is_menu = false, icon = 1, parent = 370336, data = { npc_id = 500316 } },
    [370338] = { id = 370338, name = "魔印: 219 - 244", is_menu = false, icon = 1, parent = 370336, data = { npc_id = 500317 } },
    [370339] = { id = 370339, name = "魔印: 245 - 263", is_menu = false, icon = 1, parent = 370336, data = { npc_id = 500318 } },
    [370340] = { id = 370340, name = "魔印: 264 - 284", is_menu = false, icon = 1, parent = 370336, data = { npc_id = 500319 } },
    [370341] = { id = 370341, name = "珠宝", is_menu = true, icon = 0, parent = 0 },
    [370342] = { id = 370342, name = "简易", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500013 } },
    [370343] = { id = 370343, name = "橙色", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500014 } },
    [370344] = { id = 370344, name = "红色", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500015 } },
    [370345] = { id = 370345, name = "绿色", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500016 } },
    [370346] = { id = 370346, name = "紫色", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500017 } },
    [370347] = { id = 370347, name = "黄色", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500018 } },
    [370348] = { id = 370348, name = "蓝色", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500019 } },
    [370349] = { id = 370349, name = "多彩", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500020 } },
    [370350] = { id = 370350, name = "棱彩", is_menu = false, icon = 1, parent = 370341, data = { npc_id = 500021 } },
    [370351] = { id = 370351, name = "雕文", is_menu = true, icon = 0, parent = 0 },
    [370352] = { id = 370352, name = "德鲁伊", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500045 } },
    [370353] = { id = 370353, name = "圣骑士", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500046 } },
    [370354] = { id = 370354, name = "萨满祭司", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500047 } },
    [370355] = { id = 370355, name = "牧师", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500048 } },
    [370356] = { id = 370356, name = "术士", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500049 } },
    [370357] = { id = 370357, name = "法师", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500050 } },
    [370358] = { id = 370358, name = "猎人", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500051 } },
    [370359] = { id = 370359, name = "盗贼", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500052 } },
    [370360] = { id = 370360, name = "战士", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500053 } },
    [370361] = { id = 370361, name = "死亡骑士", is_menu = false, icon = 1, parent = 370351, data = { npc_id = 500054 } },
    [370362] = { id = 370362, name = "消耗品", is_menu = true, icon = 0, parent = 0 },
    [370363] = { id = 370363, name = "药水", is_menu = false, icon = 1, parent = 370362, data = { npc_id = 500022 } },
    [370364] = { id = 370364, name = "药剂", is_menu = false, icon = 1, parent = 370362, data = { npc_id = 500023 } },
    [370365] = { id = 370365, name = "合剂", is_menu = false, icon = 1, parent = 370362, data = { npc_id = 500024 } },
    [370366] = { id = 370366, name = "食物和饮料", is_menu = false, icon = 1, parent = 370362, data = { npc_id = 500025 } },
    [370367] = { id = 370367, name = "其他", is_menu = false, icon = 1, parent = 370362, data = { npc_id = 500026 } },
    [370368] = { id = 370368, name = "容器", is_menu = true, icon = 0, parent = 0 },
    [370369] = { id = 370369, name = "容器", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500027 } },
    [370370] = { id = 370370, name = "工程学材料袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500028 } },
    [370371] = { id = 370371, name = "宝石袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500029 } },
    [370372] = { id = 370372, name = "制皮袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500030 } },
    [370373] = { id = 370373, name = "草药袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500031 } },
    [370374] = { id = 370374, name = "矿石袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500032 } },
    [370375] = { id = 370375, name = "灵魂袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500033 } },
    [370376] = { id = 370376, name = "附魔材料袋", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500034 } },
    [370377] = { id = 370377, name = "铭文包", is_menu = false, icon = 1, parent = 370368, data = { npc_id = 500035 } },
    [370378] = { id = 370378, name = "箭袋", is_menu = true, icon = 0, parent = 0 },
    [370379] = { id = 370379, name = "箭袋", is_menu = false, icon = 1, parent = 370378, data = { npc_id = 500036 } },
    [370380] = { id = 370380, name = "弹药袋", is_menu = false, icon = 1, parent = 370378, data = { npc_id = 500037 } },
    [370381] = { id = 370381, name = "弹药", is_menu = true, icon = 0, parent = 0 },
    [370382] = { id = 370382, name = "枪用", is_menu = false, icon = 1, parent = 370381, data = { npc_id = 500055 } },
    [370383] = { id = 370383, name = "弓用", is_menu = false, icon = 1, parent = 370381, data = { npc_id = 500056 } },
    [370384] = { id = 370384, name = "商品", is_menu = true, icon = 0, parent = 0 },
    [370385] = { id = 370385, name = "金属和矿石", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500005 } },
    [370386] = { id = 370386, name = "皮革", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500003 } },
    [370387] = { id = 370387, name = "布料", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500004 } },
    [370388] = { id = 370388, name = "草药", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500002 } },
    [370389] = { id = 370389, name = "附魔", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500008 } },
    [370390] = { id = 370390, name = "元素", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500009 } },
    [370391] = { id = 370391, name = "珠宝加工", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500011 } },
    [370392] = { id = 370392, name = "零件", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500006 } },
    [370393] = { id = 370393, name = "装置", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500007 } },
    [370394] = { id = 370394, name = "原料", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500012 } },
    [370395] = { id = 370395, name = "肉类", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500001 } },
    [370396] = { id = 370396, name = "其他", is_menu = false, icon = 1, parent = 370384, data = { npc_id = 500010 } },
    [370397] = { id = 370397, name = "其它", is_menu = true, icon = 0, parent = 0 },
    [370398] = { id = 370398, name = "坐骑", is_menu = true, icon = 0, parent = 370397 },
    [370399] = { id = 370399, name = "坐骑: 制造业成品", is_menu = false, icon = 1, parent = 370398, data = { npc_id = 500067 } },
    [370400] = { id = 370400, name = "任务", is_menu = true, icon = 0, parent = 0 },
    [370401] = { id = 370401, name = "任务", is_menu = false, icon = 1, parent = 370400, data = { npc_id = 500038 } },
}

function CpiMultiVendor.FindIdByKeyValue(
    choiceDataMapper,
    choiceDataKey,
    choiceDataValue
)
    --[[
    这个函数的目的是查找第一个 key, value pair 符合条件的 choiceData 的 id.

    类似于 ``SELECT ID FROM table WHERE table.choiceDataKey = choiceDataValue LIMIT 1``.

    :type choiceDataMapper: table
    :param choiceDataMapper: 一个 {id: choiceData} 的字典, 其中 id 是整数.
    :type choiceDataKey: string
    :param choiceDataKey: choiceData 中的 key
    :type choiceDataKey: any
    :param choiceDataValue: choiceData 中的 value

    :return: 符合条件的 choiceData 的 id.
    --]]
    --print("    ----- Start: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
    --print(string.format("      choiceDataMapper = %s", choiceDataMapper)) -- for debug only
    --print(string.format("      choiceDataKey = %s", choiceDataKey)) -- for debug only
    --print(string.format("      choiceDataValue = %s", choiceDataValue)) -- for debug only
    for choiceDataId, choiceData in pairs(choiceDataMapper) do
        if choiceDataKey then
            if choiceData[choiceDataKey] == choiceDataValue then
                --print("    ----- End: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
                return choiceDataId
            end
        else -- 貌似无论如何都不会进入到这段逻辑中
            if choiceData == choiceDataValue then
                --print("    ----- End: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
                return choiceDataId
            end
        end
    end
    --print("    ----- End: CpiMultiVendor.FindIdByKeyValue(...) ------") -- for debug only
end

function CpiMultiVendor.FindAllByKeyValue(
    choiceDataMapper,
    choiceDataKey,
    choiceDataValue
)
    --[[
    这个函数的目的是查找所有 key, value pair 符合条件的 choiceData 的列表.

    类似于 ``SELECT ID FROM table WHERE talbe.choiceDataKey = choiceDataValue``.

    :type choiceDataMapper: table
    :param choiceDataMapper: 一个 {id: choiceData} 的字典, 其中 ID 是整数.
    :type choiceDataKey: string
    :param choiceDataKey: choiceData 中的 key
    :type choiceDataKey: any
    :param choiceDataValue: choiceData 中的 value

    :return: 符合条件的所有 choiceData 的列表.
    --]]
    print("    ----- Start: CpiMultiVendor.FindAllByKeyValue(...) ------") -- for debug only
    print(string.format("      choiceDataMapper = %s", choiceDataMapper)) -- for debug only
    print(string.format("      choiceDataKey = %s", choiceDataKey)) -- for debug only
    print(string.format("      choiceDataValue = %s", choiceDataValue)) -- for debug only
    local choiceDataList = {}
    -- 注: 这里必须用 ipairs, 确保顺序和定义的顺序一致
    for choiceDataId, choiceData in pairs(choiceDataMapper) do
        print(string.format("      choiceDataId = %s", choiceDataId)) -- for debug only
        if choiceDataKey then
            if choiceData[choiceDataKey] == choiceDataValue then
                table.insert(choiceDataList, choiceData)
            end
        else
            if choiceData == choiceDataValue then
                table.insert(choiceDataList, choiceData)
            end
        end
    end
    print("    ----- End: CpiMultiVendor.FindAllByKeyValue(...) ------") -- for debug only
    return choiceDataList
end


local choiceDataList = CpiMultiVendor.FindAllByKeyValue(
    CpiMultiVendor.CHOICE_DATA_MAPPER,
    "parent",
    0
)