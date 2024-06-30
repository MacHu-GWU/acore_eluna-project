.. _cpi-multivendor-lua:

CPI MultiVendor Lua
==============================================================================


Overview
------------------------------------------------------------------------------
在 `CPI (Consumer Price Index) <https://acore-db-app.readthedocs.io/en/latest/search.html?q=CPI+Consumer+price+index&check_keywords=yes&area=default>`_ 中提到了, 我们为了增加私服体验, 我们修改了很多材料的购买和出售价格来模拟拍卖行中的出售和购买行为. 在这个项目中, 我们创建了一个 `cpi_multivendor.lua <https://github.com/MacHu-GWU/acore_eluna-project/blob/main/manage/workspace/lua_scripts/cpi_multivendor.lua>`_ 脚本, 用来让玩家找一个特殊的 NPC, 然后进入商店菜单来购买这些物品. 由于我们总计会开发几一千多个物品, 所以我们将这些物品分门别类放在了不同的商店中, 然后为这个 NPC 创建了一个层级结构的菜单来让玩家选择不同的商店.


How it Work
------------------------------------------------------------------------------
第一步, 我们需在数据库中创建许多 NPC Vendor 的定义. 这部分内容请参考 `CPI (Consumer Price Index) <https://acore-db-app.readthedocs.io/en/latest/search.html?q=CPI+Consumer+price+index&check_keywords=yes&area=default>`_.

第二步, 有了许多 Vendor 之后, 我们需要将它们按照层级结构组织起来. 这个步骤我在这个 `Google Sheet <https://docs.google.com/spreadsheets/d/1e4I2-d4JyVbsvOcdePruqev-rkyYYMUPrwkI_fieIYw/edit?gid=1169636448#gid=1169636448>`_ 中进行.

第三步, 将 Google Sheet 中的内容拷贝到本地 `cpi_multivendor_lua_data.tsv <https://github.com/search?q=repo%3AMacHu-GWU%2Facore_eluna-project+cpi_multivendor_lua_data.tsv&type=code>`_ 文件中. 然后用 `gen_lua.py <https://github.com/search?q=repo%3AMacHu-GWU%2Facore_eluna-project+gen_lua.py&type=code>`_ 将其转化为 Lua 脚本.

.. dropdown:: gen_lua.py

    .. literalinclude:: ./gen_lua.py
       :language: lua
       :linenos:

最终生成的 Lua 脚本长这个样子:

.. dropdown:: cpi_multivendor.lua

    .. literalinclude:: ./cpi_multivendor.lua
       :language: lua
       :linenos:

如果想了解这个脚本的原理, 请仔细阅读其中的注释.

然后, 就可以将其放到 `manage/workspace/lua_scripts/ <https://github.com/MacHu-GWU/acore_eluna-project/tree/main/manage/workspace/lua_scripts>`_ 目录下, 然后运行 `manage/remote_bootstrap.py <https://github.com/MacHu-GWU/acore_eluna-project/blob/main/manage/remote_bootstrap.py>`_ 脚本将其部署到 EC2 服务器上并自动 reload 既可. 注意游戏服务器 (包括 worldserver) 必须是已经启动的状态,
