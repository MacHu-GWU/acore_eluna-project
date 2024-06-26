--[[
这个例子非常强大. 可以让你创建相当于自定义的 GM 命令. 这也是对于 GM 来说在游戏中调用 lua 脚本
最简单的方法之一. 例如我们可以创建一个 GM 命令, 当 GM 输入 #tele 就会跳出一个传送菜单.

但是如果你希望让游戏中的玩家也能够调用一些 lua 脚本, 你的触发器最好设定为用 item 触发, 然后
指定一系列任务确保只有特定的玩家会拥有这个 item. 例如下面这两个 event:

- RegisterItemEvent: https://www.azerothcore.org/pages/eluna/Global/RegisterItemEvent.html
- RegisterItemGossipEvent: https://www.azerothcore.org/pages/eluna/Global/RegisterItemGossipEvent.html
--]]
local ChatPrefix = "#example"

--[[
Parameters:

- msg: 玩家 chat 输入的消息的字符串, 这里的 find 是一个字符串的方法.
--]]
local function ChatSystem(event, player, msg, _, lang)
    if (msg:find(ChatPrefix) == 1) then
        player:SendNotification("Example Chat Command Works")
    end
end

--[[
- RegisterPlayerEvent: https://www.azerothcore.org/pages/eluna/Global/RegisterPlayerEvent.html
--]]
RegisterPlayerEvent(18, ChatSystem)