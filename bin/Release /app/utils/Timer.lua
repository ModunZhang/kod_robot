local Timer = class("Timer")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local NetManager = NetManager
function Timer:ctor()
    self.time_listeners = {}
end
function Timer:Clear()
    self.time_listeners = {}
end
function Timer:AddListener(listener)
    table.insert(self.time_listeners, listener)
end
function Timer:RemoveListener(listener)
    for i, v in ipairs(self.time_listeners) do
        if v == listener then
            table.remove(self.time_listeners, i)
            break
        end
    end
end
function Timer:GetServerTime()
    return NetManager:getServerTime() / 1000.0
end
function Timer:OnTimer(dt)
    -- LuaUtils:TimeCollect(function()
    for _,v in pairs(self.time_listeners) do
        v:OnTimer(self:GetServerTime())
    end
    -- end)
end
function Timer:Start()
    if not self.handle then
        self.handle = scheduler.scheduleGlobal(handler(self, self.OnTimer), 1.0, false)
    end
end
function Timer:Stop()
    if self.handle then
        scheduler.unscheduleGlobal(self.handle)
        self.handle = nil
    end
end

return Timer


