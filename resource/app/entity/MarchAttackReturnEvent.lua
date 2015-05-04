--
-- Author: Danny He
-- Date: 2014-12-19 17:07:03
--
local MarchAttackEvent = import(".MarchAttackEvent")
local MarchAttackReturnEvent = class("MarchAttackReturnEvent", MarchAttackEvent)

function MarchAttackReturnEvent:GetPlayerRole()
	local Me_Id = User:Id()
	if Me_Id == self:AttackPlayerData().id then
		return self.MARCH_EVENT_PLAYER_ROLE.RECEIVER
	elseif Me_Id == self:GetDefenceData().id then
		return self.MARCH_EVENT_PLAYER_ROLE.SENDER
	else
		return self.MARCH_EVENT_PLAYER_ROLE.NOTHING 
	end
end

function MarchAttackReturnEvent:FromLocation()
	return self:GetDefenceData().location,self:GetDefenceData().alliance.id
end

function MarchAttackReturnEvent:TargetLocation()
	return self:AttackPlayerData().location,self:AttackPlayerData().alliance.id
end


function MarchAttackEvent:IsMarchAttackEvent()
	return false
end

return MarchAttackReturnEvent