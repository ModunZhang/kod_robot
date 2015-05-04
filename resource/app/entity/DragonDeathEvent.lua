--
-- Author: Danny He
-- Date: 2015-01-28 11:49:50
--
local DragonEvent = import(".DragonEvent")
local DragonDeathEvent = class("DragonDeathEvent", DragonEvent)

function DragonDeathEvent:OnTimer(current_time)
	self.times_ = math.ceil(self:FinishTime() - current_time)
	if self.times_ >= 0 then
		self:NotifyObservers(function(listener)
			listener:OnDragonDeathEventTimer(self)
		end)
	end
end

return DragonDeathEvent