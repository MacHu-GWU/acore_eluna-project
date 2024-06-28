--[[
这个脚本用于让玩家通过跟特定 NPC 对话, 打开购买物品的菜单.
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
下面是所有 ICON 代码的枚举. 你可以在 "OptionIcon" 一节中看到所有图标的说明.
See: https://www.azerothcore.org/wiki/gossip_menu_option
--]]
local GOSSIP_ICON_VENDOR = 1 -- Brown bag
local GOSSIP_ICON_TRAINER = 3 -- Book
local GOSSIP_ICON_TALK = 7 -- White chat bubble with black dots (...)

--[[
下面是所有跟业务逻辑有关的常量.
--]]
local NPC_TEXT_ID_1 = 1 -- Greetings, $n
local CPI_VENDOR_ENTRY = 5005001 -- 这个 NPC flag 需要是 129
local EMPTY_SENDER = 0 -- 用于标识没有 sender 的情况
local ROOT_VENDOR_DATA_PARENT_ID = 0 -- 如果一个菜单没有 parent, 那么它的 PARENT_ID 属性的值就是这个

--[[
这是我们所有跟 vendor 相关的逻辑的 namespace table. 它类似于面向对象中的类一样, 有属性也有方法.

例如后面的 CpiMultiVendor.OnGossip() 就是一个方法.
--]]
local CpiMultiVendor = {}

--[[
VENDOR_DATA_LIST

把你希望给玩家看到的传送菜单的数据按照层级结构放在这个列表中. 这里的每条记录叫做一个 vendorData.
一条 vendorData 对应着传送菜单上的一个按钮, 也对应着一个传送坐标.
--]]
CpiMultiVendor.VENDOR_DATA_LIST = {
    {name = "武器",
        {name = "双手剑",
            {name = "双手剑: 200 - 218", vendor_id = 500068},
            {name = "双手剑: 219 - 244", vendor_id = 500069},
            {name = "双手剑: 245 - 263", vendor_id = 500070},
            {name = "双手剑: 264 - 284", vendor_id = 500071},
            {name = "双手剑: 制造业成品", vendor_id = 500063},
        },
        {name = "单手剑",
            {name = "单手剑: 200 - 218", vendor_id = 500072},
            {name = "单手剑: 219 - 244", vendor_id = 500073},
            {name = "单手剑: 245 - 263", vendor_id = 500074},
            {name = "单手剑: 264 - 284", vendor_id = 500075},
            {name = "单手剑: 制造业成品", vendor_id = 500059},
        },
        {name = "双手斧",
            {name = "双手斧: 200 - 218", vendor_id = 500088},
            {name = "双手斧: 219 - 244", vendor_id = 500089},
            {name = "双手斧: 245 - 263", vendor_id = 500090},
            {name = "双手斧: 264 - 284", vendor_id = 500091},
            {name = "双手斧: 制造业成品", vendor_id = 500058},
        },
        {name = "单手斧",
            {name = "单手斧: 200 - 218", vendor_id = 500080},
            {name = "单手斧: 219 - 244", vendor_id = 500081},
            {name = "单手斧: 245 - 263", vendor_id = 500082},
            {name = "单手斧: 264 - 284", vendor_id = 500083},
            {name = "单手斧: 制造业成品", vendor_id = 500064},
        },
        {name = "双手锤",
            {name = "双手锤: 200 - 218", vendor_id = 500104},
            {name = "双手锤: 219 - 244", vendor_id = 500105},
            {name = "双手锤: 245 - 263", vendor_id = 500106},
            {name = "双手锤: 264 - 284", vendor_id = 500107},
            {name = "双手锤: 制造业成品", vendor_id = 500065},
        },
        {name = "单手锤",
            {name = "单手锤: 200 - 218", vendor_id = 500076},
            {name = "单手锤: 219 - 244", vendor_id = 500077},
            {name = "单手锤: 245 - 263", vendor_id = 500078},
            {name = "单手锤: 264 - 284", vendor_id = 500079},
            {name = "单手锤: 制造业成品", vendor_id = 500061},
        },
        {name = "长柄武器",
            {name = "长柄武器: 200 - 218", vendor_id = 500108},
            {name = "长柄武器: 219 - 244", vendor_id = 500109},
            {name = "长柄武器: 245 - 263", vendor_id = 500110},
            {name = "长柄武器: 264 - 284", vendor_id = 500111},
        },
        {name = "法杖",
            {name = "法杖: 200 - 218", vendor_id = 500084},
            {name = "法杖: 219 - 244", vendor_id = 500085},
            {name = "法杖: 245 - 263", vendor_id = 500086},
            {name = "法杖: 264 - 284", vendor_id = 500087},
        },
        {name = "魔杖",
            {name = "魔杖: 200 - 218", vendor_id = 500112},
            {name = "魔杖: 219 - 244", vendor_id = 500113},
            {name = "魔杖: 245 - 263", vendor_id = 500114},
            {name = "魔杖: 264 - 284", vendor_id = 500115},
            {name = "魔杖: 制造业成品", vendor_id = 500066},
        },
        {name = "匕首",
            {name = "匕首: 200 - 218", vendor_id = 500096},
            {name = "匕首: 219 - 244", vendor_id = 500097},
            {name = "匕首: 245 - 263", vendor_id = 500098},
            {name = "匕首: 264 - 284", vendor_id = 500099},
            {name = "匕首: 制造业成品", vendor_id = 500060},
        },
        {name = "拳套",
            {name = "拳套: 200 - 218", vendor_id = 500116},
            {name = "拳套: 219 - 244", vendor_id = 500117},
            {name = "拳套: 245 - 263", vendor_id = 500118},
            {name = "拳套: 264 - 284", vendor_id = 500119},
        },
        {name = "弓",
            {name = "弓: 200 - 218", vendor_id = 500100},
            {name = "弓: 219 - 244", vendor_id = 500101},
            {name = "弓: 245 - 263", vendor_id = 500102},
            {name = "弓: 264 - 284", vendor_id = 500103},
        },
        {name = "弩",
            {name = "弩: 200 - 218", vendor_id = 500120},
            {name = "弩: 219 - 244", vendor_id = 500121},
            {name = "弩: 245 - 263", vendor_id = 500122},
            {name = "弩: 264 - 284", vendor_id = 500123},
        },
        {name = "枪",
            {name = "枪: 200 - 218", vendor_id = 500092},
            {name = "枪: 219 - 244", vendor_id = 500093},
            {name = "枪: 245 - 263", vendor_id = 500094},
            {name = "枪: 264 - 284", vendor_id = 500095},
            {name = "枪: 制造业成品", vendor_id = 500057},
        },
        {name = "投掷武器",
            {name = "投掷武器: 200 - 218", vendor_id = 500124},
            {name = "投掷武器: 219 - 244", vendor_id = 500125},
            {name = "投掷武器: 245 - 263", vendor_id = 500126},
            {name = "投掷武器: 264 - 284", vendor_id = 500127},
            {name = "投掷武器: 制造业成品", vendor_id = 500062},
        },
        {name = "鱼杆",
            {name = "鱼杆: 200 - 218", vendor_id = 500128},
            {name = "鱼杆: 219 - 244", vendor_id = 500129},
            {name = "鱼杆: 245 - 263", vendor_id = 500130},
            {name = "鱼杆: 264 - 284", vendor_id = 500131},
        },
    },
    {name = "护甲",
        {name = "板甲",
            {name = "头部",
                {name = "头部: 200 - 218", vendor_id = 500276},
                {name = "头部: 219 - 244", vendor_id = 500277},
                {name = "头部: 245 - 263", vendor_id = 500278},
                {name = "头部: 264 - 284", vendor_id = 500279},
            },
            {name = "肩部",
                {name = "肩部: 200 - 218", vendor_id = 500288},
                {name = "肩部: 219 - 244", vendor_id = 500289},
                {name = "肩部: 245 - 263", vendor_id = 500290},
                {name = "肩部: 264 - 284", vendor_id = 500291},
            },
            {name = "胸部",
                {name = "胸部: 200 - 218", vendor_id = 500280},
                {name = "胸部: 219 - 244", vendor_id = 500281},
                {name = "胸部: 245 - 263", vendor_id = 500282},
                {name = "胸部: 264 - 284", vendor_id = 500283},
            },
            {name = "手腕",
                {name = "手腕: 200 - 218", vendor_id = 500296},
                {name = "手腕: 219 - 244", vendor_id = 500297},
                {name = "手腕: 245 - 263", vendor_id = 500298},
                {name = "手腕: 264 - 284", vendor_id = 500299},
            },
            {name = "手部",
                {name = "手部: 200 - 218", vendor_id = 500272},
                {name = "手部: 219 - 244", vendor_id = 500273},
                {name = "手部: 245 - 263", vendor_id = 500274},
                {name = "手部: 264 - 284", vendor_id = 500275},
            },
            {name = "腰部",
                {name = "腰部: 200 - 218", vendor_id = 500300},
                {name = "腰部: 219 - 244", vendor_id = 500301},
                {name = "腰部: 245 - 263", vendor_id = 500302},
                {name = "腰部: 264 - 284", vendor_id = 500303},
            },
            {name = "腿部",
                {name = "腿部: 200 - 218", vendor_id = 500292},
                {name = "腿部: 219 - 244", vendor_id = 500293},
                {name = "腿部: 245 - 263", vendor_id = 500294},
                {name = "腿部: 264 - 284", vendor_id = 500295},
            },
            {name = "脚部",
                {name = "脚部: 200 - 218", vendor_id = 500284},
                {name = "脚部: 219 - 244", vendor_id = 500285},
                {name = "脚部: 245 - 263", vendor_id = 500286},
                {name = "脚部: 264 - 284", vendor_id = 500287},
            },
            {name = "板甲: 制造业成品", vendor_id = 500042},
        },
        {name = "锁甲",
            {name = "头部",
                {name = "头部: 200 - 218", vendor_id = 500240},
                {name = "头部: 219 - 244", vendor_id = 500241},
                {name = "头部: 245 - 263", vendor_id = 500242},
                {name = "头部: 264 - 284", vendor_id = 500243},
            },
            {name = "肩部",
                {name = "肩部: 200 - 218", vendor_id = 500256},
                {name = "肩部: 219 - 244", vendor_id = 500257},
                {name = "肩部: 245 - 263", vendor_id = 500258},
                {name = "肩部: 264 - 284", vendor_id = 500259},
            },
            {name = "胸部",
                {name = "胸部: 200 - 218", vendor_id = 500236},
                {name = "胸部: 219 - 244", vendor_id = 500237},
                {name = "胸部: 245 - 263", vendor_id = 500238},
                {name = "胸部: 264 - 284", vendor_id = 500239},
            },
            {name = "长袍",
                {name = "长袍: 200 - 218", vendor_id = 500268},
                {name = "长袍: 219 - 244", vendor_id = 500269},
                {name = "长袍: 245 - 263", vendor_id = 500270},
                {name = "长袍: 264 - 284", vendor_id = 500271},
            },
            {name = "手腕",
                {name = "手腕: 200 - 218", vendor_id = 500264},
                {name = "手腕: 219 - 244", vendor_id = 500265},
                {name = "手腕: 245 - 263", vendor_id = 500266},
                {name = "手腕: 264 - 284", vendor_id = 500267},
            },
            {name = "手部",
                {name = "手部: 200 - 218", vendor_id = 500248},
                {name = "手部: 219 - 244", vendor_id = 500249},
                {name = "手部: 245 - 263", vendor_id = 500250},
                {name = "手部: 264 - 284", vendor_id = 500251},
            },
            {name = "腰部",
                {name = "腰部: 200 - 218", vendor_id = 500260},
                {name = "腰部: 219 - 244", vendor_id = 500261},
                {name = "腰部: 245 - 263", vendor_id = 500262},
                {name = "腰部: 264 - 284", vendor_id = 500263},
            },
            {name = "腿部",
                {name = "腿部: 200 - 218", vendor_id = 500244},
                {name = "腿部: 219 - 244", vendor_id = 500245},
                {name = "腿部: 245 - 263", vendor_id = 500246},
                {name = "腿部: 264 - 284", vendor_id = 500247},
            },
            {name = "脚部",
                {name = "脚部: 200 - 218", vendor_id = 500252},
                {name = "脚部: 219 - 244", vendor_id = 500253},
                {name = "脚部: 245 - 263", vendor_id = 500254},
                {name = "脚部: 264 - 284", vendor_id = 500255},
            },
            {name = "锁甲: 制造业成品", vendor_id = 500040},
        },
        {name = "皮甲",
            {name = "头部",
                {name = "头部: 200 - 218", vendor_id = 500184},
                {name = "头部: 219 - 244", vendor_id = 500185},
                {name = "头部: 245 - 263", vendor_id = 500186},
                {name = "头部: 264 - 284", vendor_id = 500187},
            },
            {name = "肩部",
                {name = "肩部: 200 - 218", vendor_id = 500180},
                {name = "肩部: 219 - 244", vendor_id = 500181},
                {name = "肩部: 245 - 263", vendor_id = 500182},
                {name = "肩部: 264 - 284", vendor_id = 500183},
            },
            {name = "胸部",
                {name = "胸部: 200 - 218", vendor_id = 500164},
                {name = "胸部: 219 - 244", vendor_id = 500165},
                {name = "胸部: 245 - 263", vendor_id = 500166},
                {name = "胸部: 264 - 284", vendor_id = 500167},
            },
            {name = "长袍",
                {name = "长袍: 200 - 218", vendor_id = 500188},
                {name = "长袍: 219 - 244", vendor_id = 500189},
                {name = "长袍: 245 - 263", vendor_id = 500190},
                {name = "长袍: 264 - 284", vendor_id = 500191},
            },
            {name = "手腕",
                {name = "手腕: 200 - 218", vendor_id = 500168},
                {name = "手腕: 219 - 244", vendor_id = 500169},
                {name = "手腕: 245 - 263", vendor_id = 500170},
                {name = "手腕: 264 - 284", vendor_id = 500171},
            },
            {name = "手部",
                {name = "手部: 200 - 218", vendor_id = 500156},
                {name = "手部: 219 - 244", vendor_id = 500157},
                {name = "手部: 245 - 263", vendor_id = 500158},
                {name = "手部: 264 - 284", vendor_id = 500159},
            },
            {name = "腰部",
                {name = "腰部: 200 - 218", vendor_id = 500172},
                {name = "腰部: 219 - 244", vendor_id = 500173},
                {name = "腰部: 245 - 263", vendor_id = 500174},
                {name = "腰部: 264 - 284", vendor_id = 500175},
            },
            {name = "腿部",
                {name = "腿部: 200 - 218", vendor_id = 500160},
                {name = "腿部: 219 - 244", vendor_id = 500161},
                {name = "腿部: 245 - 263", vendor_id = 500162},
                {name = "腿部: 264 - 284", vendor_id = 500163},
            },
            {name = "脚部",
                {name = "脚部: 200 - 218", vendor_id = 500176},
                {name = "脚部: 219 - 244", vendor_id = 500177},
                {name = "脚部: 245 - 263", vendor_id = 500178},
                {name = "脚部: 264 - 284", vendor_id = 500179},
            },
            {name = "皮甲: 制造业成品", vendor_id = 500041},
        },
        {name = "布甲",
            {name = "头部",
                {name = "头部: 200 - 218", vendor_id = 500196},
                {name = "头部: 219 - 244", vendor_id = 500197},
                {name = "头部: 245 - 263", vendor_id = 500198},
                {name = "头部: 264 - 284", vendor_id = 500199},
            },
            {name = "肩部",
                {name = "肩部: 200 - 218", vendor_id = 500216},
                {name = "肩部: 219 - 244", vendor_id = 500217},
                {name = "肩部: 245 - 263", vendor_id = 500218},
                {name = "肩部: 264 - 284", vendor_id = 500219},
            },
            {name = "长袍",
                {name = "长袍: 200 - 218", vendor_id = 500192},
                {name = "长袍: 219 - 244", vendor_id = 500193},
                {name = "长袍: 245 - 263", vendor_id = 500194},
                {name = "长袍: 264 - 284", vendor_id = 500195},
            },
            {name = "胸部",
                {name = "胸部: 200 - 218", vendor_id = 500228},
                {name = "胸部: 219 - 244", vendor_id = 500229},
                {name = "胸部: 245 - 263", vendor_id = 500230},
                {name = "胸部: 264 - 284", vendor_id = 500231},
            },
            {name = "手腕",
                {name = "手腕: 200 - 218", vendor_id = 500220},
                {name = "手腕: 219 - 244", vendor_id = 500221},
                {name = "手腕: 245 - 263", vendor_id = 500222},
                {name = "手腕: 264 - 284", vendor_id = 500223},
            },
            {name = "手部",
                {name = "手部: 200 - 218", vendor_id = 500204},
                {name = "手部: 219 - 244", vendor_id = 500205},
                {name = "手部: 245 - 263", vendor_id = 500206},
                {name = "手部: 264 - 284", vendor_id = 500207},
            },
            {name = "腰部",
                {name = "腰部: 200 - 218", vendor_id = 500224},
                {name = "腰部: 219 - 244", vendor_id = 500225},
                {name = "腰部: 245 - 263", vendor_id = 500226},
                {name = "腰部: 264 - 284", vendor_id = 500227},
            },
            {name = "腿部",
                {name = "腿部: 200 - 218", vendor_id = 500212},
                {name = "腿部: 219 - 244", vendor_id = 500213},
                {name = "腿部: 245 - 263", vendor_id = 500214},
                {name = "腿部: 264 - 284", vendor_id = 500215},
            },
            {name = "脚部",
                {name = "脚部: 200 - 218", vendor_id = 500208},
                {name = "脚部: 219 - 244", vendor_id = 500209},
                {name = "脚部: 245 - 263", vendor_id = 500210},
                {name = "脚部: 264 - 284", vendor_id = 500211},
            },
            {name = "背部",
                {name = "背部: 200 - 218", vendor_id = 500200},
                {name = "背部: 219 - 244", vendor_id = 500201},
                {name = "背部: 245 - 263", vendor_id = 500202},
                {name = "背部: 264 - 284", vendor_id = 500203},
            },
            {name = "布甲: 制造业成品", vendor_id = 500044},
        },
        {name = "其它戒指等",
            {name = "颈部",
                {name = "颈部: 200 - 218", vendor_id = 500140},
                {name = "颈部: 219 - 244", vendor_id = 500141},
                {name = "颈部: 245 - 263", vendor_id = 500142},
                {name = "颈部: 264 - 284", vendor_id = 500143},
            },
            {name = "副手物品",
                {name = "副手物品: 200 - 218", vendor_id = 500144},
                {name = "副手物品: 219 - 244", vendor_id = 500145},
                {name = "副手物品: 245 - 263", vendor_id = 500146},
                {name = "副手物品: 264 - 284", vendor_id = 500147},
            },
            {name = "手指",
                {name = "手指: 200 - 218", vendor_id = 500136},
                {name = "手指: 219 - 244", vendor_id = 500137},
                {name = "手指: 245 - 263", vendor_id = 500138},
                {name = "手指: 264 - 284", vendor_id = 500139},
            },
            {name = "饰品",
                {name = "饰品: 200 - 218", vendor_id = 500132},
                {name = "饰品: 219 - 244", vendor_id = 500133},
                {name = "饰品: 245 - 263", vendor_id = 500134},
                {name = "饰品: 264 - 284", vendor_id = 500135},
            },
            {name = "衬衣",
                {name = "衬衣: 200 - 218", vendor_id = 500152},
                {name = "衬衣: 219 - 244", vendor_id = 500153},
                {name = "衬衣: 245 - 263", vendor_id = 500154},
                {name = "衬衣: 264 - 284", vendor_id = 500155},
            },
            {name = "徽章",
                {name = "徽章: 200 - 218", vendor_id = 500148},
                {name = "徽章: 219 - 244", vendor_id = 500149},
                {name = "徽章: 245 - 263", vendor_id = 500150},
                {name = "徽章: 264 - 284", vendor_id = 500151},
            },
            {name = "其它戒指等: 制造业成品", vendor_id = 500039},
        },
        {name = "盾牌",
            {name = "盾牌",
                {name = "盾牌: 200 - 218", vendor_id = 500232},
                {name = "盾牌: 219 - 244", vendor_id = 500233},
                {name = "盾牌: 245 - 263", vendor_id = 500234},
                {name = "盾牌: 264 - 284", vendor_id = 500235},
            },
            {name = "盾牌: 制造业成品", vendor_id = 500043},
        },
        {name = "图腾圣物圣契符印",
            {name = "圣契",
                {name = "圣契: 200 - 218", vendor_id = 500312},
                {name = "圣契: 219 - 244", vendor_id = 500313},
                {name = "圣契: 245 - 263", vendor_id = 500314},
                {name = "圣契: 264 - 284", vendor_id = 500315},
            },
            {name = "图腾",
                {name = "图腾: 200 - 218", vendor_id = 500304},
                {name = "图腾: 219 - 244", vendor_id = 500305},
                {name = "图腾: 245 - 263", vendor_id = 500306},
                {name = "图腾: 264 - 284", vendor_id = 500307},
            },
            {name = "神像",
                {name = "神像: 200 - 218", vendor_id = 500308},
                {name = "神像: 219 - 244", vendor_id = 500309},
                {name = "神像: 245 - 263", vendor_id = 500310},
                {name = "神像: 264 - 284", vendor_id = 500311},
            },
            {name = "魔印",
                {name = "魔印: 200 - 218", vendor_id = 500316},
                {name = "魔印: 219 - 244", vendor_id = 500317},
                {name = "魔印: 245 - 263", vendor_id = 500318},
                {name = "魔印: 264 - 284", vendor_id = 500319},
            },
        },
    },
    {name = "珠宝",
        {name = "简易", vendor_id = 500013},
        {name = "橙色", vendor_id = 500014},
        {name = "红色", vendor_id = 500015},
        {name = "绿色", vendor_id = 500016},
        {name = "紫色", vendor_id = 500017},
        {name = "黄色", vendor_id = 500018},
        {name = "蓝色", vendor_id = 500019},
        {name = "多彩", vendor_id = 500020},
        {name = "棱彩", vendor_id = 500021},
    },
    {name = "雕文",
        {name = "德鲁伊", vendor_id = 500045},
        {name = "圣骑士", vendor_id = 500046},
        {name = "萨满祭司", vendor_id = 500047},
        {name = "牧师", vendor_id = 500048},
        {name = "术士", vendor_id = 500049},
        {name = "法师", vendor_id = 500050},
        {name = "猎人", vendor_id = 500051},
        {name = "盗贼", vendor_id = 500052},
        {name = "战士", vendor_id = 500053},
        {name = "死亡骑士", vendor_id = 500054},
    },
    {name = "消耗品",
        {name = "药水", vendor_id = 500022},
        {name = "药剂", vendor_id = 500023},
        {name = "合剂", vendor_id = 500024},
        {name = "食物和饮料", vendor_id = 500025},
        {name = "其他", vendor_id = 500026},
    },
    {name = "容器",
        {name = "容器", vendor_id = 500027},
        {name = "工程学材料袋", vendor_id = 500028},
        {name = "宝石袋", vendor_id = 500029},
        {name = "制皮袋", vendor_id = 500030},
        {name = "草药袋", vendor_id = 500031},
        {name = "矿石袋", vendor_id = 500032},
        {name = "灵魂袋", vendor_id = 500033},
        {name = "附魔材料袋", vendor_id = 500034},
        {name = "铭文包", vendor_id = 500035},
    },
    {name = "箭袋",
        {name = "箭袋", vendor_id = 500036},
        {name = "弹药袋", vendor_id = 500037},
    },
    {name = "弹药",
        {name = "枪用", vendor_id = 500055},
        {name = "弓用", vendor_id = 500056},
    },
    {name = "商品",
        {name = "金属和矿石", vendor_id = 500005},
        {name = "皮革", vendor_id = 500003},
        {name = "布料", vendor_id = 500004},
        {name = "草药", vendor_id = 500002},
        {name = "附魔", vendor_id = 500008},
        {name = "元素", vendor_id = 500009},
        {name = "珠宝加工", vendor_id = 500011},
        {name = "零件", vendor_id = 500006},
        {name = "装置", vendor_id = 500007},
        {name = "原料", vendor_id = 500012},
        {name = "肉类", vendor_id = 500001},
        {name = "其他", vendor_id = 500010},
    },
    {name = "其它",
        {name = "坐骑",
            {name = "坐骑: 制造业成品", vendor_id = 500067},
        },
    },
    {name = "任务",
        {name = "任务", vendor_id = 500038},
    },
}

--[[
VENDOR_DATA_MAPPER

这个变量是最终展现给玩家的菜单的数据容器. 它是类似于一个 Python 字典的结构. 其中 key 是
vendorData 的唯一 ID, value 是 vendorData 本身.

{
    1: {"name": "...", "vendor_id": ...},
    2: {"name": "...", "vendor_id": ...},
    ...
}
--]]
CpiMultiVendor.VENDOR_DATA_MAPPER = {}

--[[
这个变量是给所有 CpiMultiVendor.VENDOR_DATA_LIST 中定义的 vendorData 分配一个
唯一的 ID, 以便精确定位. 这个变量会在 CpiMultiVendor.Analyse 函数中被用到,
每次处理完一个 vendorData 就会 + 1.
--]]
local idCount = 1
function CpiMultiVendor.Preprocess(vendorDataList, parentVendorDataId)
    --[[
    这个函数是对 CpiMultiVendor.VENDOR_DATA_LIST 表中的数据进行解析, 给
    CpiMultiVendor.VENDOR_DATA_MAPPER 表填充数据. 这个函数用到了递归.

    :param vendorDataList: 这是一个列表, 里面的元素是类似于
        {name = "达拉然 飞行管理员", mapid = 571, x = 5813.0, y = 448.0, z = 658.8, o = 0}
        这样的字典.
    :param parentVendorDataId: 这是一个数字, 用于标识当前 vendorDataList 的父级菜单.
    --]]
    -- 类似于 Python 中的 enumerate 函数, 返回一个索引和值的元组
    for ind, vendorData in ipairs(vendorDataList) do
        -- 由 CpiMultiVendor.Analyse 给 vendorData 添加的属性全大写,
        -- 用于和 vendorData 中原来就有的属性区分开来.
        -- 给这个 vendorData 分配一个唯一的 ID
        vendorData.ID = idCount
        -- 记录这个 vendorData 的父菜单是哪个, 如果没有父级菜单则设为 0
        vendorData.PARENT_ID = parentVendorDataId
        -- 如果 icon 没指定, 就默认用 Taxi (一个小翅膀那个)
        vendorData.ICON = vendorData.icon or GOSSIP_ICON_VENDOR
        idCount = idCount + 1
        -- 将这个 vendorData 添加到 CpiMultiVendor.VENDOR_DATA_MAPPER 表中
        CpiMultiVendor.VENDOR_DATA_MAPPER[vendorData.ID] = vendorData
        print(string.format("vendorData.ID = %s, vendorData.PARENT_ID = %s, vendorData.name = %s", vendorData.ID, vendorData.PARENT_ID, vendorData.name))

        if not vendorData.vendor_id then
            -- 如果连 vendor id 都没有, 那么就是一个菜单, 所以把 ICON 设为 Trainer (一本书那个)
            CpiMultiVendor.VENDOR_DATA_MAPPER[vendorData.ID].ICON = vendorData.icon or GOSSIP_ICON_TRAINER
            -- 因为我们知道这是一个菜单, 所以递归调用 CpiMultiVendor.Analyse 函数
            -- 遍历这个菜单下面的所有 vendorData, 并且将它们的 parentVendorDataId 都设为当前 vendorData 的 ID
            CpiMultiVendor.Preprocess(vendorData, vendorData.ID)
        end
    end
end

--print("Start: convert CpiMultiVendor.VENDOR_DATA_LIST to CpiMultiVendor.VENDOR_DATA_MAPPER ...") -- for debug only
CpiMultiVendor.Preprocess(CpiMultiVendor.VENDOR_DATA_LIST, 0)
--print("End: convert CpiMultiVendor.VENDOR_DATA_LIST to CpiMultiVendor.VENDOR_DATA_MAPPER ...") -- for debug only

function CpiMultiVendor.FindIdByKeyValue(vendorDataMapper, vendorDataKey, vendorDataValue)
    --[[
    这个函数的目的是查找第一个 key, value pair 符合条件的 vendorData 的 ID.

    类似于 ``SELECT ID FROM table WHERE table.vendorDataKey = vendorDataValue LIMIT 1``.

    :type vendorDataMapper: table
    :param vendorDataMapper: 一个 {ID: vendorData} 的字典, 其中 ID 是整数.
    :type vendorDataKey: string
    :param vendorDataKey: vendorData 中的 key
    :type vendorDataKey: any
    :param vendorDataValue: vendorData 中的 value

    :return: 符合条件的 vendorData 的 ID.
    --]]
    for vendorDataId, vendorData in pairs(vendorDataMapper) do
        if vendorDataKey then
            if vendorData[vendorDataKey] == vendorDataValue then
                return vendorDataId
            end
        else -- 貌似无论如何都不会进入到这段逻辑中
            if vendorData == vendorDataValue then
                return vendorDataId
            end
        end
    end
end

function CpiMultiVendor.FindAllByKeyValue(vendorDataMapper, vendorDataKey, vendorDataValue)
    --[[
    这个函数的目的是查找所有 key, value pair 符合条件的 vendorData 的列表.

    类似于 ``SELECT ID FROM table WHERE talbe.vendorDataKey = vendorDataValue``.

    :type vendorDataMapper: table
    :param vendorDataMapper: 一个 {ID: vendorData} 的字典, 其中 ID 是整数.
    :type vendorDataKey: string
    :param vendorDataKey: vendorData 中的 key
    :type vendorDataKey: any
    :param vendorDataValue: vendorData 中的 value

    :return: 符合条件的所有 vendorData 的列表.
    --]]
    local vendorDataList = {}
    for vendorDataId, vendorData in pairs(vendorDataMapper) do
        if vendorDataKey then
            if vendorData[vendorDataKey] == vendorDataValue then
                table.insert(vendorDataList, vendorData)
            end
        else
            if vendorData == vendorDataValue then
                table.insert(vendorDataList, vendorData)
            end
        end
    end
    return vendorDataList
end

function CpiMultiVendor.BuildMenu(sender, player, parentVendorDataId)
    --[[
    这个函数会是我们用来构建菜单的自定义函数.
    --]]

    --[[
    1. 先根据当前给定的 parentVendorDataId 找到所有的子菜单. 如果 parentVendorDataId 是 0,
    那么就是最顶层的菜单.
    --]]
    local arg_vendorDataMapper = CpiMultiVendor.VENDOR_DATA_MAPPER
    local arg_vendorDataKey = "PARENT_ID"
    local arg_vendorDataValue = parentVendorDataId
    local vendorDataList = CpiMultiVendor.FindAllByKeyValue(
        arg_vendorDataMapper,
        arg_vendorDataKey,
        arg_vendorDataValue
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

    for _, vendorData in ipairs(vendorDataList) do
        local arg_icon = vendorData.ICON
        local arg_msg = vendorData.name
        local arg_sender = EMPTY_SENDER
        local arg_intid = vendorData.ID -- 这个 item 的唯一 ID
        player:GossipMenuAddItem(
            arg_icon,
            arg_msg,
            arg_sender,
            arg_intid
        )
    end

    --[[
    2. 如果 parentVendorDataId 大于 0, 说明我们在一个子菜单中, 那么我们需要添加一个返回上一级菜单的选项.
    --]]
    if parentVendorDataId > 0 then
        arg_vendorDataMapper = CpiMultiVendor.VENDOR_DATA_MAPPER
        arg_vendorDataKey = "ID"
        arg_vendorDataValue = parentVendorDataId

        local vendorDataId = CpiMultiVendor.FindIdByKeyValue(
            arg_vendorDataMapper,
            arg_vendorDataKey,
            arg_vendorDataValue
        )

        local arg_icon = GOSSIP_ICON_TALK
        local arg_msg = "Back to "
        local arg_sender = EMPTY_SENDER
        local arg_intid = CpiMultiVendor.VENDOR_DATA_MAPPER[vendorDataId].PARENT_ID
        player:GossipMenuAddItem(arg_icon, arg_msg, arg_sender, arg_intid)
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
    player:GossipSendMenu(NPC_TEXT_ID_1, sender)
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

    if event == 1 or intid == 0 then
        --player:SendNotification("Got: GOSSIP_EVENT_ON_HELLO event") -- for debug only
        CpiMultiVendor.BuildMenu(creature, player, ROOT_VENDOR_DATA_PARENT_ID)
    else
        --player:SendNotification("Got: GOSSIP_EVENT_ON_SELECT event") -- for debug only
        local vendorDataMapper = CpiMultiVendor.VENDOR_DATA_MAPPER
        local vendorDataKey = "ID"
        local vendorDataValue = intid
        local vendorDataId = CpiMultiVendor.FindIdByKeyValue(
            vendorDataMapper,
            vendorDataKey,
            vendorDataValue
        )
        --print(string.format("Player select the %s item", intid)) -- for debug only
        local vendorData = CpiMultiVendor.VENDOR_DATA_MAPPER[vendorDataId]
        if not vendorData then
            error("This should not happen") -- for debug only
        end
        -- 获得了被选中的 vendorData, 就进入到后续的处理逻辑
        -- 如果 vendorData 中有 vendor_id 字段, 那么就需要传送玩家
        if vendorData.vendor_id then
            player:SendListInventory(creature, vendorData.vendor_id)
            player:GossipComplete()
            --print("Exit: CpiMultiVendor.OnGossip(...)") -- for debug only
            return
        end

        --[[
        如果 vendorData 中既没有 mapid 字段, 那么有两种情况:

        1. 这是一个 submenu 的 gossip item: 此时这个 intid 就是 submenu 的 ID.
            我们将其穿给 CpiMultiVendor.BuildMenu 既可进入到下一级菜单.
        2. 这是一个 "返回" 的 gossip item: 此时这个 intid ... TODO 完善这里的文档.
        --]]
        CpiMultiVendor.BuildMenu(creature, player, intid)
        --print("Exit: GOSSIP_EVENT_ON_SELECT branch") -- for debug only
    end
end

--[[
下面是 RegisterCreatureGossipEvent 的 event code
See: https://www.azerothcore.org/pages/eluna/Global/RegisterCreatureGossipEvent.html
--]]
RegisterCreatureGossipEvent(CPI_VENDOR_ENTRY, GOSSIP_EVENT_ON_HELLO, CpiMultiVendor.OnGossip)
RegisterCreatureGossipEvent(CPI_VENDOR_ENTRY, GOSSIP_EVENT_ON_SELECT, CpiMultiVendor.OnGossip)