CPI MultiVendor Lua
==============================================================================


Overview
------------------------------------------------------------------------------
在 `CPI (Consumer Price Index) <https://acore-db-app.readthedocs.io/en/latest/search.html?q=CPI+Consumer+price+index&check_keywords=yes&area=default>`_ 中提到了, 我们为了增加私服体验, 我们修改了很多材料的购买和出售价格来模拟拍卖行中的出售和购买行为. 在这个项目中, 我们创建了一个 `cpi_multivendor.lua <https://github.com/MacHu-GWU/acore_eluna-project/blob/main/manage/workspace/lua_scripts/cpi_multivendor.lua>`_ 脚本, 用来让玩家找一个特殊的 NPC, 然后进入商店菜单来购买这些物品. 由于我们总计会开发几一千多个物品, 所以我们将这些物品分门别类放在了不同的商店中, 然后为这个 NPC 创建了一个层级结构的菜单来让玩家选择不同的商店.


CPI (Consumer Price Index)

https://docs.google.com/spreadsheets/d/1e4I2-d4JyVbsvOcdePruqev-rkyYYMUPrwkI_fieIYw/edit?gid=1169636448#gid=1169636448