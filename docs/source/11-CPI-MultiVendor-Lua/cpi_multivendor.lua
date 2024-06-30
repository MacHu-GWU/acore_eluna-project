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
    [1] = { id = 1, name = "武器", is_menu = true, icon = 0, parent = 0 },
    [2] = { id = 2, name = "双手剑", is_menu = true, icon = 0, parent = 1 },
    [3] = { id = 3, name = "双手剑: 200 - 218", is_menu = false, icon = 1, parent = 2, data = { npc_id = 500068 } },
    [4] = { id = 4, name = "双手剑: 219 - 244", is_menu = false, icon = 1, parent = 2, data = { npc_id = 500069 } },
    [5] = { id = 5, name = "双手剑: 245 - 263", is_menu = false, icon = 1, parent = 2, data = { npc_id = 500070 } },
    [6] = { id = 6, name = "双手剑: 264 - 284", is_menu = false, icon = 1, parent = 2, data = { npc_id = 500071 } },
    [7] = { id = 7, name = "双手剑: 制造业成品", is_menu = false, icon = 1, parent = 2, data = { npc_id = 500063 } },
    [8] = { id = 8, name = "单手剑", is_menu = true, icon = 0, parent = 1 },
    [9] = { id = 9, name = "单手剑: 200 - 218", is_menu = false, icon = 1, parent = 8, data = { npc_id = 500072 } },
    [10] = { id = 10, name = "单手剑: 219 - 244", is_menu = false, icon = 1, parent = 8, data = { npc_id = 500073 } },
    [11] = { id = 11, name = "单手剑: 245 - 263", is_menu = false, icon = 1, parent = 8, data = { npc_id = 500074 } },
    [12] = { id = 12, name = "单手剑: 264 - 284", is_menu = false, icon = 1, parent = 8, data = { npc_id = 500075 } },
    [13] = { id = 13, name = "单手剑: 制造业成品", is_menu = false, icon = 1, parent = 8, data = { npc_id = 500059 } },
    [14] = { id = 14, name = "双手斧", is_menu = true, icon = 0, parent = 1 },
    [15] = { id = 15, name = "双手斧: 200 - 218", is_menu = false, icon = 1, parent = 14, data = { npc_id = 500088 } },
    [16] = { id = 16, name = "双手斧: 219 - 244", is_menu = false, icon = 1, parent = 14, data = { npc_id = 500089 } },
    [17] = { id = 17, name = "双手斧: 245 - 263", is_menu = false, icon = 1, parent = 14, data = { npc_id = 500090 } },
    [18] = { id = 18, name = "双手斧: 264 - 284", is_menu = false, icon = 1, parent = 14, data = { npc_id = 500091 } },
    [19] = { id = 19, name = "双手斧: 制造业成品", is_menu = false, icon = 1, parent = 14, data = { npc_id = 500058 } },
    [20] = { id = 20, name = "单手斧", is_menu = true, icon = 0, parent = 1 },
    [21] = { id = 21, name = "单手斧: 200 - 218", is_menu = false, icon = 1, parent = 20, data = { npc_id = 500080 } },
    [22] = { id = 22, name = "单手斧: 219 - 244", is_menu = false, icon = 1, parent = 20, data = { npc_id = 500081 } },
    [23] = { id = 23, name = "单手斧: 245 - 263", is_menu = false, icon = 1, parent = 20, data = { npc_id = 500082 } },
    [24] = { id = 24, name = "单手斧: 264 - 284", is_menu = false, icon = 1, parent = 20, data = { npc_id = 500083 } },
    [25] = { id = 25, name = "单手斧: 制造业成品", is_menu = false, icon = 1, parent = 20, data = { npc_id = 500064 } },
    [26] = { id = 26, name = "双手锤", is_menu = true, icon = 0, parent = 1 },
    [27] = { id = 27, name = "双手锤: 200 - 218", is_menu = false, icon = 1, parent = 26, data = { npc_id = 500104 } },
    [28] = { id = 28, name = "双手锤: 219 - 244", is_menu = false, icon = 1, parent = 26, data = { npc_id = 500105 } },
    [29] = { id = 29, name = "双手锤: 245 - 263", is_menu = false, icon = 1, parent = 26, data = { npc_id = 500106 } },
    [30] = { id = 30, name = "双手锤: 264 - 284", is_menu = false, icon = 1, parent = 26, data = { npc_id = 500107 } },
    [31] = { id = 31, name = "双手锤: 制造业成品", is_menu = false, icon = 1, parent = 26, data = { npc_id = 500065 } },
    [32] = { id = 32, name = "单手锤", is_menu = true, icon = 0, parent = 1 },
    [33] = { id = 33, name = "单手锤: 200 - 218", is_menu = false, icon = 1, parent = 32, data = { npc_id = 500076 } },
    [34] = { id = 34, name = "单手锤: 219 - 244", is_menu = false, icon = 1, parent = 32, data = { npc_id = 500077 } },
    [35] = { id = 35, name = "单手锤: 245 - 263", is_menu = false, icon = 1, parent = 32, data = { npc_id = 500078 } },
    [36] = { id = 36, name = "单手锤: 264 - 284", is_menu = false, icon = 1, parent = 32, data = { npc_id = 500079 } },
    [37] = { id = 37, name = "单手锤: 制造业成品", is_menu = false, icon = 1, parent = 32, data = { npc_id = 500061 } },
    [38] = { id = 38, name = "长柄武器", is_menu = true, icon = 0, parent = 1 },
    [39] = { id = 39, name = "长柄武器: 200 - 218", is_menu = false, icon = 1, parent = 38, data = { npc_id = 500108 } },
    [40] = { id = 40, name = "长柄武器: 219 - 244", is_menu = false, icon = 1, parent = 38, data = { npc_id = 500109 } },
    [41] = { id = 41, name = "长柄武器: 245 - 263", is_menu = false, icon = 1, parent = 38, data = { npc_id = 500110 } },
    [42] = { id = 42, name = "长柄武器: 264 - 284", is_menu = false, icon = 1, parent = 38, data = { npc_id = 500111 } },
    [43] = { id = 43, name = "法杖", is_menu = true, icon = 0, parent = 1 },
    [44] = { id = 44, name = "法杖: 200 - 218", is_menu = false, icon = 1, parent = 43, data = { npc_id = 500084 } },
    [45] = { id = 45, name = "法杖: 219 - 244", is_menu = false, icon = 1, parent = 43, data = { npc_id = 500085 } },
    [46] = { id = 46, name = "法杖: 245 - 263", is_menu = false, icon = 1, parent = 43, data = { npc_id = 500086 } },
    [47] = { id = 47, name = "法杖: 264 - 284", is_menu = false, icon = 1, parent = 43, data = { npc_id = 500087 } },
    [48] = { id = 48, name = "魔杖", is_menu = true, icon = 0, parent = 1 },
    [49] = { id = 49, name = "魔杖: 200 - 218", is_menu = false, icon = 1, parent = 48, data = { npc_id = 500112 } },
    [50] = { id = 50, name = "魔杖: 219 - 244", is_menu = false, icon = 1, parent = 48, data = { npc_id = 500113 } },
    [51] = { id = 51, name = "魔杖: 245 - 263", is_menu = false, icon = 1, parent = 48, data = { npc_id = 500114 } },
    [52] = { id = 52, name = "魔杖: 264 - 284", is_menu = false, icon = 1, parent = 48, data = { npc_id = 500115 } },
    [53] = { id = 53, name = "魔杖: 制造业成品", is_menu = false, icon = 1, parent = 48, data = { npc_id = 500066 } },
    [54] = { id = 54, name = "匕首", is_menu = true, icon = 0, parent = 1 },
    [55] = { id = 55, name = "匕首: 200 - 218", is_menu = false, icon = 1, parent = 54, data = { npc_id = 500096 } },
    [56] = { id = 56, name = "匕首: 219 - 244", is_menu = false, icon = 1, parent = 54, data = { npc_id = 500097 } },
    [57] = { id = 57, name = "匕首: 245 - 263", is_menu = false, icon = 1, parent = 54, data = { npc_id = 500098 } },
    [58] = { id = 58, name = "匕首: 264 - 284", is_menu = false, icon = 1, parent = 54, data = { npc_id = 500099 } },
    [59] = { id = 59, name = "匕首: 制造业成品", is_menu = false, icon = 1, parent = 54, data = { npc_id = 500060 } },
    [60] = { id = 60, name = "拳套", is_menu = true, icon = 0, parent = 1 },
    [61] = { id = 61, name = "拳套: 200 - 218", is_menu = false, icon = 1, parent = 60, data = { npc_id = 500116 } },
    [62] = { id = 62, name = "拳套: 219 - 244", is_menu = false, icon = 1, parent = 60, data = { npc_id = 500117 } },
    [63] = { id = 63, name = "拳套: 245 - 263", is_menu = false, icon = 1, parent = 60, data = { npc_id = 500118 } },
    [64] = { id = 64, name = "拳套: 264 - 284", is_menu = false, icon = 1, parent = 60, data = { npc_id = 500119 } },
    [65] = { id = 65, name = "弓", is_menu = true, icon = 0, parent = 1 },
    [66] = { id = 66, name = "弓: 200 - 218", is_menu = false, icon = 1, parent = 65, data = { npc_id = 500100 } },
    [67] = { id = 67, name = "弓: 219 - 244", is_menu = false, icon = 1, parent = 65, data = { npc_id = 500101 } },
    [68] = { id = 68, name = "弓: 245 - 263", is_menu = false, icon = 1, parent = 65, data = { npc_id = 500102 } },
    [69] = { id = 69, name = "弓: 264 - 284", is_menu = false, icon = 1, parent = 65, data = { npc_id = 500103 } },
    [70] = { id = 70, name = "弩", is_menu = true, icon = 0, parent = 1 },
    [71] = { id = 71, name = "弩: 200 - 218", is_menu = false, icon = 1, parent = 70, data = { npc_id = 500120 } },
    [72] = { id = 72, name = "弩: 219 - 244", is_menu = false, icon = 1, parent = 70, data = { npc_id = 500121 } },
    [73] = { id = 73, name = "弩: 245 - 263", is_menu = false, icon = 1, parent = 70, data = { npc_id = 500122 } },
    [74] = { id = 74, name = "弩: 264 - 284", is_menu = false, icon = 1, parent = 70, data = { npc_id = 500123 } },
    [75] = { id = 75, name = "枪", is_menu = true, icon = 0, parent = 1 },
    [76] = { id = 76, name = "枪: 200 - 218", is_menu = false, icon = 1, parent = 75, data = { npc_id = 500092 } },
    [77] = { id = 77, name = "枪: 219 - 244", is_menu = false, icon = 1, parent = 75, data = { npc_id = 500093 } },
    [78] = { id = 78, name = "枪: 245 - 263", is_menu = false, icon = 1, parent = 75, data = { npc_id = 500094 } },
    [79] = { id = 79, name = "枪: 264 - 284", is_menu = false, icon = 1, parent = 75, data = { npc_id = 500095 } },
    [80] = { id = 80, name = "枪: 制造业成品", is_menu = false, icon = 1, parent = 75, data = { npc_id = 500057 } },
    [81] = { id = 81, name = "投掷武器", is_menu = true, icon = 0, parent = 1 },
    [82] = { id = 82, name = "投掷武器: 200 - 218", is_menu = false, icon = 1, parent = 81, data = { npc_id = 500124 } },
    [83] = { id = 83, name = "投掷武器: 219 - 244", is_menu = false, icon = 1, parent = 81, data = { npc_id = 500125 } },
    [84] = { id = 84, name = "投掷武器: 245 - 263", is_menu = false, icon = 1, parent = 81, data = { npc_id = 500126 } },
    [85] = { id = 85, name = "投掷武器: 264 - 284", is_menu = false, icon = 1, parent = 81, data = { npc_id = 500127 } },
    [86] = { id = 86, name = "投掷武器: 制造业成品", is_menu = false, icon = 1, parent = 81, data = { npc_id = 500062 } },
    [87] = { id = 87, name = "鱼杆", is_menu = true, icon = 0, parent = 1 },
    [88] = { id = 88, name = "鱼杆: 200 - 218", is_menu = false, icon = 1, parent = 87, data = { npc_id = 500128 } },
    [89] = { id = 89, name = "鱼杆: 219 - 244", is_menu = false, icon = 1, parent = 87, data = { npc_id = 500129 } },
    [90] = { id = 90, name = "鱼杆: 245 - 263", is_menu = false, icon = 1, parent = 87, data = { npc_id = 500130 } },
    [91] = { id = 91, name = "鱼杆: 264 - 284", is_menu = false, icon = 1, parent = 87, data = { npc_id = 500131 } },
    [92] = { id = 92, name = "护甲", is_menu = true, icon = 0, parent = 0 },
    [93] = { id = 93, name = "板甲", is_menu = true, icon = 0, parent = 92 },
    [94] = { id = 94, name = "头部", is_menu = true, icon = 0, parent = 93 },
    [95] = { id = 95, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 94, data = { npc_id = 500276 } },
    [96] = { id = 96, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 94, data = { npc_id = 500277 } },
    [97] = { id = 97, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 94, data = { npc_id = 500278 } },
    [98] = { id = 98, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 94, data = { npc_id = 500279 } },
    [99] = { id = 99, name = "肩部", is_menu = true, icon = 0, parent = 93 },
    [100] = { id = 100, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 99, data = { npc_id = 500288 } },
    [101] = { id = 101, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 99, data = { npc_id = 500289 } },
    [102] = { id = 102, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 99, data = { npc_id = 500290 } },
    [103] = { id = 103, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 99, data = { npc_id = 500291 } },
    [104] = { id = 104, name = "胸部", is_menu = true, icon = 0, parent = 93 },
    [105] = { id = 105, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 104, data = { npc_id = 500280 } },
    [106] = { id = 106, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 104, data = { npc_id = 500281 } },
    [107] = { id = 107, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 104, data = { npc_id = 500282 } },
    [108] = { id = 108, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 104, data = { npc_id = 500283 } },
    [109] = { id = 109, name = "手腕", is_menu = true, icon = 0, parent = 93 },
    [110] = { id = 110, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 109, data = { npc_id = 500296 } },
    [111] = { id = 111, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 109, data = { npc_id = 500297 } },
    [112] = { id = 112, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 109, data = { npc_id = 500298 } },
    [113] = { id = 113, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 109, data = { npc_id = 500299 } },
    [114] = { id = 114, name = "手部", is_menu = true, icon = 0, parent = 93 },
    [115] = { id = 115, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 114, data = { npc_id = 500272 } },
    [116] = { id = 116, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 114, data = { npc_id = 500273 } },
    [117] = { id = 117, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 114, data = { npc_id = 500274 } },
    [118] = { id = 118, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 114, data = { npc_id = 500275 } },
    [119] = { id = 119, name = "腰部", is_menu = true, icon = 0, parent = 93 },
    [120] = { id = 120, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 119, data = { npc_id = 500300 } },
    [121] = { id = 121, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 119, data = { npc_id = 500301 } },
    [122] = { id = 122, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 119, data = { npc_id = 500302 } },
    [123] = { id = 123, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 119, data = { npc_id = 500303 } },
    [124] = { id = 124, name = "腿部", is_menu = true, icon = 0, parent = 93 },
    [125] = { id = 125, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 124, data = { npc_id = 500292 } },
    [126] = { id = 126, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 124, data = { npc_id = 500293 } },
    [127] = { id = 127, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 124, data = { npc_id = 500294 } },
    [128] = { id = 128, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 124, data = { npc_id = 500295 } },
    [129] = { id = 129, name = "脚部", is_menu = true, icon = 0, parent = 93 },
    [130] = { id = 130, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 129, data = { npc_id = 500284 } },
    [131] = { id = 131, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 129, data = { npc_id = 500285 } },
    [132] = { id = 132, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 129, data = { npc_id = 500286 } },
    [133] = { id = 133, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 129, data = { npc_id = 500287 } },
    [134] = { id = 134, name = "板甲: 制造业成品", is_menu = false, icon = 1, parent = 93, data = { npc_id = 500042 } },
    [135] = { id = 135, name = "锁甲", is_menu = true, icon = 0, parent = 92 },
    [136] = { id = 136, name = "头部", is_menu = true, icon = 0, parent = 135 },
    [137] = { id = 137, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 136, data = { npc_id = 500240 } },
    [138] = { id = 138, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 136, data = { npc_id = 500241 } },
    [139] = { id = 139, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 136, data = { npc_id = 500242 } },
    [140] = { id = 140, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 136, data = { npc_id = 500243 } },
    [141] = { id = 141, name = "肩部", is_menu = true, icon = 0, parent = 135 },
    [142] = { id = 142, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 141, data = { npc_id = 500256 } },
    [143] = { id = 143, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 141, data = { npc_id = 500257 } },
    [144] = { id = 144, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 141, data = { npc_id = 500258 } },
    [145] = { id = 145, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 141, data = { npc_id = 500259 } },
    [146] = { id = 146, name = "胸部", is_menu = true, icon = 0, parent = 135 },
    [147] = { id = 147, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 146, data = { npc_id = 500236 } },
    [148] = { id = 148, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 146, data = { npc_id = 500237 } },
    [149] = { id = 149, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 146, data = { npc_id = 500238 } },
    [150] = { id = 150, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 146, data = { npc_id = 500239 } },
    [151] = { id = 151, name = "长袍", is_menu = true, icon = 0, parent = 135 },
    [152] = { id = 152, name = "长袍: 200 - 218", is_menu = false, icon = 1, parent = 151, data = { npc_id = 500268 } },
    [153] = { id = 153, name = "长袍: 219 - 244", is_menu = false, icon = 1, parent = 151, data = { npc_id = 500269 } },
    [154] = { id = 154, name = "长袍: 245 - 263", is_menu = false, icon = 1, parent = 151, data = { npc_id = 500270 } },
    [155] = { id = 155, name = "长袍: 264 - 284", is_menu = false, icon = 1, parent = 151, data = { npc_id = 500271 } },
    [156] = { id = 156, name = "手腕", is_menu = true, icon = 0, parent = 135 },
    [157] = { id = 157, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 156, data = { npc_id = 500264 } },
    [158] = { id = 158, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 156, data = { npc_id = 500265 } },
    [159] = { id = 159, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 156, data = { npc_id = 500266 } },
    [160] = { id = 160, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 156, data = { npc_id = 500267 } },
    [161] = { id = 161, name = "手部", is_menu = true, icon = 0, parent = 135 },
    [162] = { id = 162, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 161, data = { npc_id = 500248 } },
    [163] = { id = 163, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 161, data = { npc_id = 500249 } },
    [164] = { id = 164, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 161, data = { npc_id = 500250 } },
    [165] = { id = 165, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 161, data = { npc_id = 500251 } },
    [166] = { id = 166, name = "腰部", is_menu = true, icon = 0, parent = 135 },
    [167] = { id = 167, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 166, data = { npc_id = 500260 } },
    [168] = { id = 168, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 166, data = { npc_id = 500261 } },
    [169] = { id = 169, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 166, data = { npc_id = 500262 } },
    [170] = { id = 170, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 166, data = { npc_id = 500263 } },
    [171] = { id = 171, name = "腿部", is_menu = true, icon = 0, parent = 135 },
    [172] = { id = 172, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 171, data = { npc_id = 500244 } },
    [173] = { id = 173, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 171, data = { npc_id = 500245 } },
    [174] = { id = 174, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 171, data = { npc_id = 500246 } },
    [175] = { id = 175, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 171, data = { npc_id = 500247 } },
    [176] = { id = 176, name = "脚部", is_menu = true, icon = 0, parent = 135 },
    [177] = { id = 177, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 176, data = { npc_id = 500252 } },
    [178] = { id = 178, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 176, data = { npc_id = 500253 } },
    [179] = { id = 179, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 176, data = { npc_id = 500254 } },
    [180] = { id = 180, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 176, data = { npc_id = 500255 } },
    [181] = { id = 181, name = "锁甲: 制造业成品", is_menu = false, icon = 1, parent = 135, data = { npc_id = 500040 } },
    [182] = { id = 182, name = "皮甲", is_menu = true, icon = 0, parent = 92 },
    [183] = { id = 183, name = "头部", is_menu = true, icon = 0, parent = 182 },
    [184] = { id = 184, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 183, data = { npc_id = 500184 } },
    [185] = { id = 185, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 183, data = { npc_id = 500185 } },
    [186] = { id = 186, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 183, data = { npc_id = 500186 } },
    [187] = { id = 187, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 183, data = { npc_id = 500187 } },
    [188] = { id = 188, name = "肩部", is_menu = true, icon = 0, parent = 182 },
    [189] = { id = 189, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 188, data = { npc_id = 500180 } },
    [190] = { id = 190, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 188, data = { npc_id = 500181 } },
    [191] = { id = 191, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 188, data = { npc_id = 500182 } },
    [192] = { id = 192, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 188, data = { npc_id = 500183 } },
    [193] = { id = 193, name = "胸部", is_menu = true, icon = 0, parent = 182 },
    [194] = { id = 194, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 193, data = { npc_id = 500164 } },
    [195] = { id = 195, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 193, data = { npc_id = 500165 } },
    [196] = { id = 196, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 193, data = { npc_id = 500166 } },
    [197] = { id = 197, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 193, data = { npc_id = 500167 } },
    [198] = { id = 198, name = "长袍", is_menu = true, icon = 0, parent = 182 },
    [199] = { id = 199, name = "长袍: 200 - 218", is_menu = false, icon = 1, parent = 198, data = { npc_id = 500188 } },
    [200] = { id = 200, name = "长袍: 219 - 244", is_menu = false, icon = 1, parent = 198, data = { npc_id = 500189 } },
    [201] = { id = 201, name = "长袍: 245 - 263", is_menu = false, icon = 1, parent = 198, data = { npc_id = 500190 } },
    [202] = { id = 202, name = "长袍: 264 - 284", is_menu = false, icon = 1, parent = 198, data = { npc_id = 500191 } },
    [203] = { id = 203, name = "手腕", is_menu = true, icon = 0, parent = 182 },
    [204] = { id = 204, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 203, data = { npc_id = 500168 } },
    [205] = { id = 205, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 203, data = { npc_id = 500169 } },
    [206] = { id = 206, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 203, data = { npc_id = 500170 } },
    [207] = { id = 207, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 203, data = { npc_id = 500171 } },
    [208] = { id = 208, name = "手部", is_menu = true, icon = 0, parent = 182 },
    [209] = { id = 209, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 208, data = { npc_id = 500156 } },
    [210] = { id = 210, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 208, data = { npc_id = 500157 } },
    [211] = { id = 211, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 208, data = { npc_id = 500158 } },
    [212] = { id = 212, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 208, data = { npc_id = 500159 } },
    [213] = { id = 213, name = "腰部", is_menu = true, icon = 0, parent = 182 },
    [214] = { id = 214, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 213, data = { npc_id = 500172 } },
    [215] = { id = 215, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 213, data = { npc_id = 500173 } },
    [216] = { id = 216, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 213, data = { npc_id = 500174 } },
    [217] = { id = 217, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 213, data = { npc_id = 500175 } },
    [218] = { id = 218, name = "腿部", is_menu = true, icon = 0, parent = 182 },
    [219] = { id = 219, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 218, data = { npc_id = 500160 } },
    [220] = { id = 220, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 218, data = { npc_id = 500161 } },
    [221] = { id = 221, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 218, data = { npc_id = 500162 } },
    [222] = { id = 222, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 218, data = { npc_id = 500163 } },
    [223] = { id = 223, name = "脚部", is_menu = true, icon = 0, parent = 182 },
    [224] = { id = 224, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 223, data = { npc_id = 500176 } },
    [225] = { id = 225, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 223, data = { npc_id = 500177 } },
    [226] = { id = 226, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 223, data = { npc_id = 500178 } },
    [227] = { id = 227, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 223, data = { npc_id = 500179 } },
    [228] = { id = 228, name = "皮甲: 制造业成品", is_menu = false, icon = 1, parent = 182, data = { npc_id = 500041 } },
    [229] = { id = 229, name = "布甲", is_menu = true, icon = 0, parent = 92 },
    [230] = { id = 230, name = "头部", is_menu = true, icon = 0, parent = 229 },
    [231] = { id = 231, name = "头部: 200 - 218", is_menu = false, icon = 1, parent = 230, data = { npc_id = 500196 } },
    [232] = { id = 232, name = "头部: 219 - 244", is_menu = false, icon = 1, parent = 230, data = { npc_id = 500197 } },
    [233] = { id = 233, name = "头部: 245 - 263", is_menu = false, icon = 1, parent = 230, data = { npc_id = 500198 } },
    [234] = { id = 234, name = "头部: 264 - 284", is_menu = false, icon = 1, parent = 230, data = { npc_id = 500199 } },
    [235] = { id = 235, name = "肩部", is_menu = true, icon = 0, parent = 229 },
    [236] = { id = 236, name = "肩部: 200 - 218", is_menu = false, icon = 1, parent = 235, data = { npc_id = 500216 } },
    [237] = { id = 237, name = "肩部: 219 - 244", is_menu = false, icon = 1, parent = 235, data = { npc_id = 500217 } },
    [238] = { id = 238, name = "肩部: 245 - 263", is_menu = false, icon = 1, parent = 235, data = { npc_id = 500218 } },
    [239] = { id = 239, name = "肩部: 264 - 284", is_menu = false, icon = 1, parent = 235, data = { npc_id = 500219 } },
    [240] = { id = 240, name = "长袍", is_menu = true, icon = 0, parent = 229 },
    [241] = { id = 241, name = "长袍: 200 - 218", is_menu = false, icon = 1, parent = 240, data = { npc_id = 500192 } },
    [242] = { id = 242, name = "长袍: 219 - 244", is_menu = false, icon = 1, parent = 240, data = { npc_id = 500193 } },
    [243] = { id = 243, name = "长袍: 245 - 263", is_menu = false, icon = 1, parent = 240, data = { npc_id = 500194 } },
    [244] = { id = 244, name = "长袍: 264 - 284", is_menu = false, icon = 1, parent = 240, data = { npc_id = 500195 } },
    [245] = { id = 245, name = "胸部", is_menu = true, icon = 0, parent = 229 },
    [246] = { id = 246, name = "胸部: 200 - 218", is_menu = false, icon = 1, parent = 245, data = { npc_id = 500228 } },
    [247] = { id = 247, name = "胸部: 219 - 244", is_menu = false, icon = 1, parent = 245, data = { npc_id = 500229 } },
    [248] = { id = 248, name = "胸部: 245 - 263", is_menu = false, icon = 1, parent = 245, data = { npc_id = 500230 } },
    [249] = { id = 249, name = "胸部: 264 - 284", is_menu = false, icon = 1, parent = 245, data = { npc_id = 500231 } },
    [250] = { id = 250, name = "手腕", is_menu = true, icon = 0, parent = 229 },
    [251] = { id = 251, name = "手腕: 200 - 218", is_menu = false, icon = 1, parent = 250, data = { npc_id = 500220 } },
    [252] = { id = 252, name = "手腕: 219 - 244", is_menu = false, icon = 1, parent = 250, data = { npc_id = 500221 } },
    [253] = { id = 253, name = "手腕: 245 - 263", is_menu = false, icon = 1, parent = 250, data = { npc_id = 500222 } },
    [254] = { id = 254, name = "手腕: 264 - 284", is_menu = false, icon = 1, parent = 250, data = { npc_id = 500223 } },
    [255] = { id = 255, name = "手部", is_menu = true, icon = 0, parent = 229 },
    [256] = { id = 256, name = "手部: 200 - 218", is_menu = false, icon = 1, parent = 255, data = { npc_id = 500204 } },
    [257] = { id = 257, name = "手部: 219 - 244", is_menu = false, icon = 1, parent = 255, data = { npc_id = 500205 } },
    [258] = { id = 258, name = "手部: 245 - 263", is_menu = false, icon = 1, parent = 255, data = { npc_id = 500206 } },
    [259] = { id = 259, name = "手部: 264 - 284", is_menu = false, icon = 1, parent = 255, data = { npc_id = 500207 } },
    [260] = { id = 260, name = "腰部", is_menu = true, icon = 0, parent = 229 },
    [261] = { id = 261, name = "腰部: 200 - 218", is_menu = false, icon = 1, parent = 260, data = { npc_id = 500224 } },
    [262] = { id = 262, name = "腰部: 219 - 244", is_menu = false, icon = 1, parent = 260, data = { npc_id = 500225 } },
    [263] = { id = 263, name = "腰部: 245 - 263", is_menu = false, icon = 1, parent = 260, data = { npc_id = 500226 } },
    [264] = { id = 264, name = "腰部: 264 - 284", is_menu = false, icon = 1, parent = 260, data = { npc_id = 500227 } },
    [265] = { id = 265, name = "腿部", is_menu = true, icon = 0, parent = 229 },
    [266] = { id = 266, name = "腿部: 200 - 218", is_menu = false, icon = 1, parent = 265, data = { npc_id = 500212 } },
    [267] = { id = 267, name = "腿部: 219 - 244", is_menu = false, icon = 1, parent = 265, data = { npc_id = 500213 } },
    [268] = { id = 268, name = "腿部: 245 - 263", is_menu = false, icon = 1, parent = 265, data = { npc_id = 500214 } },
    [269] = { id = 269, name = "腿部: 264 - 284", is_menu = false, icon = 1, parent = 265, data = { npc_id = 500215 } },
    [270] = { id = 270, name = "脚部", is_menu = true, icon = 0, parent = 229 },
    [271] = { id = 271, name = "脚部: 200 - 218", is_menu = false, icon = 1, parent = 270, data = { npc_id = 500208 } },
    [272] = { id = 272, name = "脚部: 219 - 244", is_menu = false, icon = 1, parent = 270, data = { npc_id = 500209 } },
    [273] = { id = 273, name = "脚部: 245 - 263", is_menu = false, icon = 1, parent = 270, data = { npc_id = 500210 } },
    [274] = { id = 274, name = "脚部: 264 - 284", is_menu = false, icon = 1, parent = 270, data = { npc_id = 500211 } },
    [275] = { id = 275, name = "背部", is_menu = true, icon = 0, parent = 229 },
    [276] = { id = 276, name = "背部: 200 - 218", is_menu = false, icon = 1, parent = 275, data = { npc_id = 500200 } },
    [277] = { id = 277, name = "背部: 219 - 244", is_menu = false, icon = 1, parent = 275, data = { npc_id = 500201 } },
    [278] = { id = 278, name = "背部: 245 - 263", is_menu = false, icon = 1, parent = 275, data = { npc_id = 500202 } },
    [279] = { id = 279, name = "背部: 264 - 284", is_menu = false, icon = 1, parent = 275, data = { npc_id = 500203 } },
    [280] = { id = 280, name = "布甲: 制造业成品", is_menu = false, icon = 1, parent = 229, data = { npc_id = 500044 } },
    [281] = { id = 281, name = "其它戒指等", is_menu = true, icon = 0, parent = 92 },
    [282] = { id = 282, name = "颈部", is_menu = true, icon = 0, parent = 281 },
    [283] = { id = 283, name = "颈部: 200 - 218", is_menu = false, icon = 1, parent = 282, data = { npc_id = 500140 } },
    [284] = { id = 284, name = "颈部: 219 - 244", is_menu = false, icon = 1, parent = 282, data = { npc_id = 500141 } },
    [285] = { id = 285, name = "颈部: 245 - 263", is_menu = false, icon = 1, parent = 282, data = { npc_id = 500142 } },
    [286] = { id = 286, name = "颈部: 264 - 284", is_menu = false, icon = 1, parent = 282, data = { npc_id = 500143 } },
    [287] = { id = 287, name = "副手物品", is_menu = true, icon = 0, parent = 281 },
    [288] = { id = 288, name = "副手物品: 200 - 218", is_menu = false, icon = 1, parent = 287, data = { npc_id = 500144 } },
    [289] = { id = 289, name = "副手物品: 219 - 244", is_menu = false, icon = 1, parent = 287, data = { npc_id = 500145 } },
    [290] = { id = 290, name = "副手物品: 245 - 263", is_menu = false, icon = 1, parent = 287, data = { npc_id = 500146 } },
    [291] = { id = 291, name = "副手物品: 264 - 284", is_menu = false, icon = 1, parent = 287, data = { npc_id = 500147 } },
    [292] = { id = 292, name = "手指", is_menu = true, icon = 0, parent = 281 },
    [293] = { id = 293, name = "手指: 200 - 218", is_menu = false, icon = 1, parent = 292, data = { npc_id = 500136 } },
    [294] = { id = 294, name = "手指: 219 - 244", is_menu = false, icon = 1, parent = 292, data = { npc_id = 500137 } },
    [295] = { id = 295, name = "手指: 245 - 263", is_menu = false, icon = 1, parent = 292, data = { npc_id = 500138 } },
    [296] = { id = 296, name = "手指: 264 - 284", is_menu = false, icon = 1, parent = 292, data = { npc_id = 500139 } },
    [297] = { id = 297, name = "饰品", is_menu = true, icon = 0, parent = 281 },
    [298] = { id = 298, name = "饰品: 200 - 218", is_menu = false, icon = 1, parent = 297, data = { npc_id = 500132 } },
    [299] = { id = 299, name = "饰品: 219 - 244", is_menu = false, icon = 1, parent = 297, data = { npc_id = 500133 } },
    [300] = { id = 300, name = "饰品: 245 - 263", is_menu = false, icon = 1, parent = 297, data = { npc_id = 500134 } },
    [301] = { id = 301, name = "饰品: 264 - 284", is_menu = false, icon = 1, parent = 297, data = { npc_id = 500135 } },
    [302] = { id = 302, name = "衬衣", is_menu = true, icon = 0, parent = 281 },
    [303] = { id = 303, name = "衬衣: 200 - 218", is_menu = false, icon = 1, parent = 302, data = { npc_id = 500152 } },
    [304] = { id = 304, name = "衬衣: 219 - 244", is_menu = false, icon = 1, parent = 302, data = { npc_id = 500153 } },
    [305] = { id = 305, name = "衬衣: 245 - 263", is_menu = false, icon = 1, parent = 302, data = { npc_id = 500154 } },
    [306] = { id = 306, name = "衬衣: 264 - 284", is_menu = false, icon = 1, parent = 302, data = { npc_id = 500155 } },
    [307] = { id = 307, name = "徽章", is_menu = true, icon = 0, parent = 281 },
    [308] = { id = 308, name = "徽章: 200 - 218", is_menu = false, icon = 1, parent = 307, data = { npc_id = 500148 } },
    [309] = { id = 309, name = "徽章: 219 - 244", is_menu = false, icon = 1, parent = 307, data = { npc_id = 500149 } },
    [310] = { id = 310, name = "徽章: 245 - 263", is_menu = false, icon = 1, parent = 307, data = { npc_id = 500150 } },
    [311] = { id = 311, name = "徽章: 264 - 284", is_menu = false, icon = 1, parent = 307, data = { npc_id = 500151 } },
    [312] = { id = 312, name = "其它戒指等: 制造业成品", is_menu = false, icon = 1, parent = 281, data = { npc_id = 500039 } },
    [313] = { id = 313, name = "盾牌", is_menu = true, icon = 0, parent = 92 },
    [314] = { id = 314, name = "盾牌", is_menu = true, icon = 0, parent = 313 },
    [315] = { id = 315, name = "盾牌: 200 - 218", is_menu = false, icon = 1, parent = 314, data = { npc_id = 500232 } },
    [316] = { id = 316, name = "盾牌: 219 - 244", is_menu = false, icon = 1, parent = 314, data = { npc_id = 500233 } },
    [317] = { id = 317, name = "盾牌: 245 - 263", is_menu = false, icon = 1, parent = 314, data = { npc_id = 500234 } },
    [318] = { id = 318, name = "盾牌: 264 - 284", is_menu = false, icon = 1, parent = 314, data = { npc_id = 500235 } },
    [319] = { id = 319, name = "盾牌: 制造业成品", is_menu = false, icon = 1, parent = 313, data = { npc_id = 500043 } },
    [320] = { id = 320, name = "图腾圣物圣契符印", is_menu = true, icon = 0, parent = 92 },
    [321] = { id = 321, name = "圣契", is_menu = true, icon = 0, parent = 320 },
    [322] = { id = 322, name = "圣契: 200 - 218", is_menu = false, icon = 1, parent = 321, data = { npc_id = 500312 } },
    [323] = { id = 323, name = "圣契: 219 - 244", is_menu = false, icon = 1, parent = 321, data = { npc_id = 500313 } },
    [324] = { id = 324, name = "圣契: 245 - 263", is_menu = false, icon = 1, parent = 321, data = { npc_id = 500314 } },
    [325] = { id = 325, name = "圣契: 264 - 284", is_menu = false, icon = 1, parent = 321, data = { npc_id = 500315 } },
    [326] = { id = 326, name = "图腾", is_menu = true, icon = 0, parent = 320 },
    [327] = { id = 327, name = "图腾: 200 - 218", is_menu = false, icon = 1, parent = 326, data = { npc_id = 500304 } },
    [328] = { id = 328, name = "图腾: 219 - 244", is_menu = false, icon = 1, parent = 326, data = { npc_id = 500305 } },
    [329] = { id = 329, name = "图腾: 245 - 263", is_menu = false, icon = 1, parent = 326, data = { npc_id = 500306 } },
    [330] = { id = 330, name = "图腾: 264 - 284", is_menu = false, icon = 1, parent = 326, data = { npc_id = 500307 } },
    [331] = { id = 331, name = "神像", is_menu = true, icon = 0, parent = 320 },
    [332] = { id = 332, name = "神像: 200 - 218", is_menu = false, icon = 1, parent = 331, data = { npc_id = 500308 } },
    [333] = { id = 333, name = "神像: 219 - 244", is_menu = false, icon = 1, parent = 331, data = { npc_id = 500309 } },
    [334] = { id = 334, name = "神像: 245 - 263", is_menu = false, icon = 1, parent = 331, data = { npc_id = 500310 } },
    [335] = { id = 335, name = "神像: 264 - 284", is_menu = false, icon = 1, parent = 331, data = { npc_id = 500311 } },
    [336] = { id = 336, name = "魔印", is_menu = true, icon = 0, parent = 320 },
    [337] = { id = 337, name = "魔印: 200 - 218", is_menu = false, icon = 1, parent = 336, data = { npc_id = 500316 } },
    [338] = { id = 338, name = "魔印: 219 - 244", is_menu = false, icon = 1, parent = 336, data = { npc_id = 500317 } },
    [339] = { id = 339, name = "魔印: 245 - 263", is_menu = false, icon = 1, parent = 336, data = { npc_id = 500318 } },
    [340] = { id = 340, name = "魔印: 264 - 284", is_menu = false, icon = 1, parent = 336, data = { npc_id = 500319 } },
    [341] = { id = 341, name = "珠宝", is_menu = true, icon = 0, parent = 0 },
    [342] = { id = 342, name = "简易", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500013 } },
    [343] = { id = 343, name = "橙色", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500014 } },
    [344] = { id = 344, name = "红色", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500015 } },
    [345] = { id = 345, name = "绿色", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500016 } },
    [346] = { id = 346, name = "紫色", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500017 } },
    [347] = { id = 347, name = "黄色", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500018 } },
    [348] = { id = 348, name = "蓝色", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500019 } },
    [349] = { id = 349, name = "多彩", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500020 } },
    [350] = { id = 350, name = "棱彩", is_menu = false, icon = 1, parent = 341, data = { npc_id = 500021 } },
    [351] = { id = 351, name = "雕文", is_menu = true, icon = 0, parent = 0 },
    [352] = { id = 352, name = "德鲁伊", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500045 } },
    [353] = { id = 353, name = "圣骑士", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500046 } },
    [354] = { id = 354, name = "萨满祭司", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500047 } },
    [355] = { id = 355, name = "牧师", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500048 } },
    [356] = { id = 356, name = "术士", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500049 } },
    [357] = { id = 357, name = "法师", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500050 } },
    [358] = { id = 358, name = "猎人", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500051 } },
    [359] = { id = 359, name = "盗贼", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500052 } },
    [360] = { id = 360, name = "战士", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500053 } },
    [361] = { id = 361, name = "死亡骑士", is_menu = false, icon = 1, parent = 351, data = { npc_id = 500054 } },
    [362] = { id = 362, name = "消耗品", is_menu = true, icon = 0, parent = 0 },
    [363] = { id = 363, name = "药水", is_menu = false, icon = 1, parent = 362, data = { npc_id = 500022 } },
    [364] = { id = 364, name = "药剂", is_menu = false, icon = 1, parent = 362, data = { npc_id = 500023 } },
    [365] = { id = 365, name = "合剂", is_menu = false, icon = 1, parent = 362, data = { npc_id = 500024 } },
    [366] = { id = 366, name = "食物和饮料", is_menu = false, icon = 1, parent = 362, data = { npc_id = 500025 } },
    [367] = { id = 367, name = "其他", is_menu = false, icon = 1, parent = 362, data = { npc_id = 500026 } },
    [368] = { id = 368, name = "容器", is_menu = true, icon = 0, parent = 0 },
    [369] = { id = 369, name = "容器", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500027 } },
    [370] = { id = 370, name = "工程学材料袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500028 } },
    [371] = { id = 371, name = "宝石袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500029 } },
    [372] = { id = 372, name = "制皮袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500030 } },
    [373] = { id = 373, name = "草药袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500031 } },
    [374] = { id = 374, name = "矿石袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500032 } },
    [375] = { id = 375, name = "灵魂袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500033 } },
    [376] = { id = 376, name = "附魔材料袋", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500034 } },
    [377] = { id = 377, name = "铭文包", is_menu = false, icon = 1, parent = 368, data = { npc_id = 500035 } },
    [378] = { id = 378, name = "箭袋", is_menu = true, icon = 0, parent = 0 },
    [379] = { id = 379, name = "箭袋", is_menu = false, icon = 1, parent = 378, data = { npc_id = 500036 } },
    [380] = { id = 380, name = "弹药袋", is_menu = false, icon = 1, parent = 378, data = { npc_id = 500037 } },
    [381] = { id = 381, name = "弹药", is_menu = true, icon = 0, parent = 0 },
    [382] = { id = 382, name = "枪用", is_menu = false, icon = 1, parent = 381, data = { npc_id = 500055 } },
    [383] = { id = 383, name = "弓用", is_menu = false, icon = 1, parent = 381, data = { npc_id = 500056 } },
    [384] = { id = 384, name = "商品", is_menu = true, icon = 0, parent = 0 },
    [385] = { id = 385, name = "金属和矿石", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500005 } },
    [386] = { id = 386, name = "皮革", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500003 } },
    [387] = { id = 387, name = "布料", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500004 } },
    [388] = { id = 388, name = "草药", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500002 } },
    [389] = { id = 389, name = "附魔", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500008 } },
    [390] = { id = 390, name = "元素", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500009 } },
    [391] = { id = 391, name = "珠宝加工", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500011 } },
    [392] = { id = 392, name = "零件", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500006 } },
    [393] = { id = 393, name = "装置", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500007 } },
    [394] = { id = 394, name = "原料", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500012 } },
    [395] = { id = 395, name = "肉类", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500001 } },
    [396] = { id = 396, name = "其他", is_menu = false, icon = 1, parent = 384, data = { npc_id = 500010 } },
    [397] = { id = 397, name = "其它", is_menu = true, icon = 0, parent = 0 },
    [398] = { id = 398, name = "坐骑", is_menu = true, icon = 0, parent = 397 },
    [399] = { id = 399, name = "坐骑: 制造业成品", is_menu = false, icon = 1, parent = 398, data = { npc_id = 500067 } },
    [400] = { id = 400, name = "任务", is_menu = true, icon = 0, parent = 0 },
    [401] = { id = 401, name = "任务", is_menu = false, icon = 1, parent = 400, data = { npc_id = 500038 } },
}

function CpiMultiVendor.FindIdByKeyValue(choiceDataMapper, choiceDataKey, choiceDataValue)
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
    for choiceDataId, choiceData in pairs(choiceDataMapper) do
        if choiceDataKey then
            if choiceData[choiceDataKey] == choiceDataValue then
                return choiceDataId
            end
        else -- 貌似无论如何都不会进入到这段逻辑中
            if choiceData == choiceDataValue then
                return choiceDataId
            end
        end
    end
end

function CpiMultiVendor.FindAllByKeyValue(choiceDataMapper, choiceDataKey, choiceDataValue)
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
    local choiceDataList = {}
    -- 注: 这里必须用 ipairs, 确保顺序和定义的顺序一致
    for choiceDataId, choiceData in ipairs(choiceDataMapper) do
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
    return choiceDataList
end

function CpiMultiVendor.BuildMenu(sender, player, parentChoiceDataId)
    --[[
    这个函数会是我们用来构建菜单的自定义函数.
    --]]

    --[[
    1. 先根据当前给定的 parentChoiceDataId 找到所有的子菜单. 如果 parentChoiceDataId 是 0,
    那么就是最顶层的菜单.
    --]]
    --print("Start: CpiMultiVendor.BuildMenu() function") -- for debug only
    --print(string.format("sender = %s", sender))
    --print(string.format("player = %s", player))
    --print(string.format("parentChoiceDataId = %s", parentChoiceDataId))
    local args = {
        choiceDataMapper = CpiMultiVendor.CHOICE_DATA_MAPPER,
        choiceDataKey = "parent",
        choiceDataValue = parentChoiceDataId,
    }
    local choiceDataList = CpiMultiVendor.FindAllByKeyValue(
        args.choiceDataMapper,
        args.choiceDataKey,
        args.choiceDataValue
    )

    --[[
    这后面的代码会频繁调用 Player:GossipMenuAddItem(...)

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
    for _, choiceData in ipairs(choiceDataList) do
        print(string.format("msg = %s", choiceData.name)) -- for debug only
        args = {
            icon = choiceData.icon,
            msg = choiceData.name,
            sender = EMPTY_SENDER,
            intid = choiceData.id -- 这个 item 的唯一 ID
        }
        player:GossipMenuAddItem(
            args.icon,
            args.msg,
            args.sender,
            args.intid
        )
    end

    --[[
    2. 如果 parentChoiceDataId 大于 0, 说明我们在一个子菜单中, 那么我们需要添加一个返回上一级菜单的选项.
    --]]
    if parentChoiceDataId > 0 then
        --print("This is a submenu, add return button") -- for debug only
        args = {
            choiceDataMapper = CpiMultiVendor.CHOICE_DATA_MAPPER,
            choiceDataKey = "id",
            choiceDataValue = parentChoiceDataId,
        }
        local choiceDataId = CpiMultiVendor.FindIdByKeyValue(
            args.choiceDataMapper,
            args.choiceDataKey,
            args.choiceDataValue
        )

        args = {
            icon = GOSSIP_ICON_TALK,
            msg = string.format("< 返回上一级菜单: %s", CpiMultiVendor.CHOICE_DATA_MAPPER[parentChoiceDataId].name),
            sender = EMPTY_SENDER,
            intid = CpiMultiVendor.CHOICE_DATA_MAPPER[choiceDataId].parent,
        }
        player:GossipMenuAddItem(
            args.icon,
            args.msg,
            args.sender,
            args.intid
        )

        args = {
            icon = GOSSIP_ICON_TALK,
            msg = "<<< 返回初始菜单",
            sender = EMPTY_SENDER,
            intid = ROOT_CHOICE_DATA_PARENT_ID,
        }
        player:GossipMenuAddItem(
            args.icon,
            args.msg,
            args.sender,
            args.intid
        )
    end

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
    args = {
        npc_text = NPC_TEXT_ID_1,
        sender = sender,
    }
    player:GossipSendMenu(
        args.npc_text,
        args.sender
        -- menu sender is a creature, so we don't need menu_id
    )
    --print("End: CpiMultiVendor.BuildMenu() function") -- for debug only
end


function CpiMultiVendor.OnGossip(event, player, creature, sender, intid, code, menu_id)
    --[[
    这个函数被用于处理 Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_SELECT event.

    在其他例子中你可能会看到还有一个相关的函数 Global:RegisterPlayerGossipEvent@GOSSIP_EVENT_ON_HELLO event
    用于处理玩家的第一次打开 gossip 菜单的情况. 但是在这个例子中, 打开菜单的动作是通过
    Player:GossipSendMenu() 方法在 CpiMultiVendor.OnChat() 中手动用代码
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
    --print("------ Enter function CpiMultiVendor.OnGossip() ------") -- for debug only
    --print(string.format("event = %s", event)) -- for debug only
    --print(string.format("player = %s", player)) -- for debug only
    --print(string.format("creature = %s", creature)) -- for debug only
    --print(string.format("sender = %s", sender)) -- for debug only
    --print(string.format("intid = %s", intid)) -- for debug only
    --print(string.format("code = %s", code)) -- for debug only
    --print(string.format("menu_id = %s", menu_id)) -- for debug only
    -- 第一次打开菜单, 那么就显示最顶层的菜单既可
    if event == 1 or intid == 0 then
        --print("Got: GOSSIP_EVENT_ON_HELLO event") -- for debug only
        local args = {
            sender = creature,
            player = player,
            parentChoiceDataId = ROOT_CHOICE_DATA_PARENT_ID,
        }
        CpiMultiVendor.BuildMenu(
            args.sender,
            args.player,
            args.parentChoiceDataId
        )
    -- 处理点击了某个菜单选项的事件. 首先我们要判断这是一个 submenu 还是一个可以立刻生效的选项
    else
        --print("Got: GOSSIP_EVENT_ON_SELECT event") -- for debug only
        local args = {
            choiceDataMapper = CpiMultiVendor.CHOICE_DATA_MAPPER,
            choiceDataKey = "id",
            choiceDataValue = intid,
        }
        local choiceDataId = CpiMultiVendor.FindIdByKeyValue(
            args.choiceDataMapper,
            args.choiceDataKey,
            args.choiceDataValue
        )
        --print(string.format("Player select the %s item", intid)) -- for debug only
        local choiceData = CpiMultiVendor.CHOICE_DATA_MAPPER[choiceDataId]
        if not choiceData then
            error("This should not happen") -- for debug only
        end
        -- 获得了被选中的 choiceData, 就进入到后续的处理逻辑
        -- 如果 choiceData 中有 data 字段, 说明被选中的事一个可以立刻生效的选项
        if choiceData.data then
            -- Ref: https://www.azerothcore.org/pages/eluna/Player/SendListInventory.html
            args = {
                sender = creature,
                vendor_id = choiceData.data.npc_id,
            }
            player:SendListInventory(
                args.sender,
                args.vendor_id
            )
            player:GossipComplete()
            --print("Exit: CpiMultiVendor.OnGossip(...)") -- for debug only
            return
        end

        --[[
        如果 choiceData 中没有 data 字段, 那么有两种情况:

        1. 这是一个 submenu 的 gossip item: 此时这个 intid 就是 submenu 的 id.
            我们将其穿给 CpiMultiVendor.BuildMenu 既可进入到下一级菜单.
        2. 这是一个 "返回 ..." 的 gossip item: 此时这个 intid 就是 parent menu 的 id.
        --]]
        args = {
            sender = creature,
            player = player,
            parentChoiceDataId = intid
        }
        CpiMultiVendor.BuildMenu(
            args.sender,
            args.player,
            args.parentChoiceDataId
        )
        --print("Exit: GOSSIP_EVENT_ON_SELECT branch") -- for debug only
    end
end

--[[
下面是 RegisterCreatureGossipEvent 的 event code
See: https://www.azerothcore.org/pages/eluna/Global/RegisterCreatureGossipEvent.html
--]]
RegisterCreatureGossipEvent(CPI_VENDOR_ENTRY, GOSSIP_EVENT_ON_HELLO, CpiMultiVendor.OnGossip)
RegisterCreatureGossipEvent(CPI_VENDOR_ENTRY, GOSSIP_EVENT_ON_SELECT, CpiMultiVendor.OnGossip)