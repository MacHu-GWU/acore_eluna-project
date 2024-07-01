local gossip_menu_utils = require("gossip_menu_utils")

local function TestBuildGossipMenuItemList()
    local gossipOptionList = {
        { id = 101, name = "东部王国", is_menu = true, icon = 1, parent = gossip_menu_utils.NO_PARENT_ID },
        { id = 102, name = "艾尔文森林", is_menu = true, icon = 1, parent = 101 },
        { id = 103, name = "北境修道院", is_menu = false, icon = 1, parent = 102, data = {} },
        { id = 104, name = "返回 艾尔文森林", is_menu = True, icon = 1, parent = 102},
        { id = 105, name = "返回 首页", is_menu = True, icon = 1, parent = 102},
        { id = 106, name = "东部王国中心", is_menu = false, icon = 1, parent = 101, data = {} },
        { id = 107, name = "返回 东部王国", is_menu = True, icon = 1, parent = 101},
        { id = 108, name = "返回 首页", is_menu = True, icon = 1, parent = 101},
        { id = 109, name = "艾泽拉斯中心", is_menu = false, icon = 1, parent = gossip_menu_utils.NO_PARENT_ID, data = {} },
    }
    local gossipOptionDict = {
        [101] = { id = 101, name = "东部王国", is_menu = true, icon = 1, parent = gossip_menu_utils.NO_PARENT_ID },
        [102] = { id = 102, name = "艾尔文森林", is_menu = true, icon = 1, parent = 101 },
        [103] = { id = 103, name = "北境修道院", is_menu = false, icon = 1, parent = 102, data = {} },
        [104] = { id = 104, name = "东部王国中心", is_menu = false, icon = 1, parent = 101, data = {} },
        [105] = { id = 105, name = "艾泽拉斯中心", is_menu = false, icon = 1, parent = gossip_menu_utils.NO_PARENT_ID, data = {} },
    }

    local gossipMenuItemList = gossip_menu_utils.BuildGossipMenuItemList(
            gossipOptionList,
            gossipOptionDict,
            gossip_menu_utils.NO_PARENT_ID
    )
    assert(#gossipMenuItemList == 2)
    assert(gossipMenuItemList[1].msg == "东部王国")
    assert(gossipMenuItemList[2].msg == "艾泽拉斯中心")

    gossipMenuItemList = gossip_menu_utils.BuildGossipMenuItemList(
            gossipOptionList,
            gossipOptionDict,
            101
    )
    assert(#gossipMenuItemList == 4)
    assert(gossipMenuItemList[1].msg == "艾尔文森林")
    assert(gossipMenuItemList[2].msg == "东部王国中心")
    assert(gossipMenuItemList[3].msg == "返回 东部王国")
    assert(gossipMenuItemList[4].msg == "返回 首页")
    assert(gossipMenuItemList[4].intid == 108)
    --
    gossipMenuItemList = gossip_menu_utils.BuildGossipMenuItemList(
            gossipOptionList,
            gossipOptionDict,
            102
    )
    assert(#gossipMenuItemList == 3)
    assert(gossipMenuItemList[1].msg == "北境修道院")
    assert(gossipMenuItemList[2].msg == "返回 艾尔文森林")
    assert(gossipMenuItemList[3].msg == "返回 首页")
    assert(gossipMenuItemList[3].intid == 105)
end

TestBuildGossipMenuItemList()
