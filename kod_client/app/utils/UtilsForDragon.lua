UtilsForDragon = {}

function UtilsForDragon:GetWeight(dragon)
	if not self:Ishated(dragon) then
		return 0
	else 
		return self:TotalStrength()
	end
end
function UtilsForDragon:Ishated(dragon)
	return dragon.star > 0
end
function UtilsForDragon:IsDefenced(dragon)
	return dragon.status == 'defence'
end
function UtilsForDragon:IsFree(dragon)
	return dragon.status == 'free'
end
function UtilsForDragon:IsDead(dragon)
	return math.floor(dragon.hp) == 0
end
local dragonStar = GameDatas.Dragons.dragonStar
local dragonLevel = GameDatas.Dragons.dragonLevel
function UtilsForDragon:GetLeadership(dragon)
	return dragonStar[dragon.star].initLeadership 
		 + dragonLevel[dragon.level].leadership
end

function UtilsForDragon:GetDefenceDragon(userData)
    for i,v in ipairs(self:GetHatedDragons(userData)) do
    	if v.status == 'defence' then
    		return v
    	end
    end
end
function UtilsForDragon:GetCanHatedDragon(userData)
	for k,v in pairs(userData.dragons) do
		if v.star <= 0 then
			return v
		end
	end
end
function UtilsForDragon:IsDragonAllHated(userData)
    local max 	= 0
	local count = 0
	for k,v in pairs(userData.dragons) do
		max = max + 1
		if v.star > 0 then
			count = count + 1
		end
	end
	return max == count
end
function UtilsForDragon:GetHatedDragons(userData)
	local hateddragons = {}
    for k,v in pairs(userData.dragons) do
		if v.star > 0 then
			table.insert(hateddragons, v)
		end
	end
	return hateddragons
end