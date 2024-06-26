--[[
阅读这个例子之前请确保你已经阅读了以下几个例子:

- hello_world.lua
--]]
local PLAYER_EVENT_ON_LOGIN = 3

local function OnLogin(event, player)
--[[
在这个例子中, 当玩家登录后我们自动给这个玩家添加一些光环效果. 这里用到的是 AddAura 这个方法,
详细文档请看 https://www.azerothcore.org/pages/eluna/Unit/AddAura.html
这里 41105 是一个受到的伤害 - 25% 的防御光环
--]]
    player:AddAura(41105, player)
end
RegisterPlayerEvent(PLAYER_EVENT_ON_LOGIN, OnLogin)