--[[
我们看代码的时候应该反着看, 从真正开始执行的地方开始看, 然后一层层拨开看里面有什么. 我建议按照
我标记的 1, 2, ... 的顺序看.
--]]
local PLAYER_EVENT_ON_LOGIN = 3

--[[
2. Event Handler

根据 PLAYER_EVENT_ON_LOGIN 的文档, event handler 的参数包括一个 event 对象和 player 对象.

这篇文档介绍了 Player 对象具有哪些方法: https://www.azerothcore.org/pages/eluna/Player/index.html

其中 SendBroadcastMessage 就是其中一个方法, 用来让系统向玩家发送广播消息.

根据这篇 Player 的文档 https://www.azerothcore.org/pages/eluna/Player/index.html,
可以看出它是继承自 Object, WorldObject, Unit 这几个对象. 也就是说它具有所有这些对象的方法.
--]]
local function OnLogin(event, player)
    player:SendBroadcastMessage("Hello Alice")
end
--[[
1. Entry point

RegisterPlayerEvent: 是一个函数, 用来注册玩家事件的.
    - 这篇文档展示了这个函数的具体用法: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
    - 这篇文档介绍了这个函数有哪些参数 (一共三个参数): https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html#arguments

这里的 PLAYER_EVENT_ON_LOGIN 是第一个参数, 相当于是一个 filter, 指定了哪些事件会触发 event handler.
    - ``PLAYER_EVENT_ON_LOGIN                   =     3,        // (event, player)`` 这一行介绍了
        这个事件有哪些参数:
        https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html

OnLogin 是我们自己实现的 event handler. 这个函数的参数列表要和 PLAYER_EVENT_ON_LOGIN 文档中说的一致.
-- ]]
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, OnLogin)