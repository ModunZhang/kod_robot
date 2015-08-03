--
-- Author: Danny He
-- Date: 2015-01-08 16:21:15
--
local BelvedereEntity = class("BelvedereEntity")
local property = import("..utils.property")
local Enum = import("..utils.Enum")
local Localize = import("..utils.Localize")
--[[ 
	MARCH_OUT:派出的正在路上（攻打城市/村落/协防）部队，
	MARCH_RETURN:正在返回路上的攻打（城市/村落/协防）部队,
	HELPTO:已经协防到其他玩家的部队,
	SHIRNE:已经在参加圣地事件的部队
	STRIKE_OUT:派出的正在路上突袭（城市/村落）部队
	STRIKE_RETURN:在返回路上的突袭（城市/村落）部队
]]--
BelvedereEntity.ENTITY_TYPE = Enum("NONE","MARCH_OUT","MARCH_RETURN","COLLECT","HELPTO","SHIRNE","STRIKE_OUT","STRIKE_RETURN")
function BelvedereEntity:OnPropertyChange()
end

function BelvedereEntity:ctor(object)
	property(self,"withObject",object)
end

function BelvedereEntity:SetType(entity_type)
	self.entity_type = entity_type
end

function BelvedereEntity:GetTypeStr()
	return self.ENTITY_TYPE[self:GetType()]
end
function BelvedereEntity:GetType()
	return self.entity_type
end

function BelvedereEntity:GetTitle()
	if self:GetType() == self.ENTITY_TYPE.HELPTO then
		return  string.format(_("正在协防玩家%s"),self:WithObject().beHelpedPlayerData.name)
	elseif self:GetType() == self.ENTITY_TYPE.COLLECT then
		return _("正在进行村落采集")
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT then
		local march_type = self:WithObject():MarchType()
		if march_type == 'city' then
			return _("进攻玩家城市(行军中)")
		elseif march_type == 'helpDefence' then
			return _("协防玩家城市(行军中)")
		elseif march_type == 'village' then
			return _("占领村落(行军中)")
		elseif march_type == 'shrine' then
			return _("攻打联盟圣地(行军中)")
		elseif march_type == 'monster' then
			return _("攻打黑龙军团(行军中)")
		end
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_RETURN then
		local march_type = self:WithObject():MarchType()
		if march_type == 'city' then
			return _("进攻玩家城市(返回中)")
		elseif march_type == 'helpDefence' then
			return _("协防玩家城市(返回中)")
		elseif march_type == 'village' then
			return _("占领村落(返回中)")
		elseif march_type == 'shrine' then
			return _("攻打联盟圣地(返回中)")
		elseif march_type == 'monster' then
			return _("攻打黑龙军团(返回中)")
		end
	elseif self:GetType() == self.ENTITY_TYPE.STRIKE_OUT then
		local march_type = self:WithObject():MarchType()
		if march_type == 'city' then
			return _("突袭玩家城市(行军中)")
		elseif march_type == 'village' then
			return _("突袭村落(行军中)")
		end
	elseif self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN then
		local march_type = self:WithObject():MarchType()
		if march_type == 'city' then
			return _("突袭玩家城市(返回中)")
		elseif march_type == 'village' then
			return _("突袭村落(返回中)")
		end
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		return self:WithObject():Stage():GetDescStageName()
	end
end
-- 获取区域地图上事件显示的前缀
function BelvedereEntity:GetEventPrefix()
	if self:GetType() == self.ENTITY_TYPE.HELPTO then
		return  string.format(_("正在协防 %s (%s)"),self:WithObject().beHelpedPlayerData.name,self:GetDestinationLocation())
	elseif self:GetType() == self.ENTITY_TYPE.COLLECT then
		return string.format(_("正在采集%sLv%s (%s)"), 
			Localize.village_name[self:WithObject():VillageData().name],
			self:WithObject():VillageData().level,
			self:GetDestinationLocation())
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT then
		local march_type = self:WithObject():MarchType()
		if march_type == 'shrine' then 
			return string.format(_("进军圣地 (%s)"),self:GetDestinationLocation())
		elseif  march_type == 'helpDefence' then
			return string.format(_("前往协防 %s(%s)"),self:GetDestination(),self:GetDestinationLocation())
		else
			return string.format(_("正在进攻 %s(%s)"),self:GetDestination(),self:GetDestinationLocation())
		end
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_RETURN then
		return string.format(_("返回中 (%s)"),self:GetDestinationLocation())
	elseif self:GetType() == self.ENTITY_TYPE.STRIKE_OUT then
		return string.format(_("正在突袭 %s(%s)"),self:GetDestination(),self:GetDestinationLocation())
	elseif self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN then
		return string.format(_("返回中 (%s)"),self:GetDestinationLocation())
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		return string.format(_("正在参加圣地战 %s(%s)"),self:WithObject():Stage():GetDescStageName(),self:GetDestinationLocation())
	end
end

function BelvedereEntity:GetDestination()
	if self:GetType() == self.ENTITY_TYPE.HELPTO then

		return self:WithObject().beHelpedPlayerData.name
	elseif self:GetType() == self.ENTITY_TYPE.COLLECT then

		return Localize.village_name[self:WithObject():VillageData().name] .. "Lv" .. self:WithObject():VillageData().level
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT  
		-- or self:GetType() == self.ENTITY_TYPE.MARCH_RETURN 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_OUT 
		-- or self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN 
		then

		if self:WithObject():MarchType() == 'city' or self:WithObject():MarchType() == 'helpDefence' then
			return self:WithObject():GetDefenceData().name
		elseif self:WithObject():MarchType() == 'village' then
			dump(self:WithObject(),"self:WithObject()---->")
			local village_data = self:WithObject():GetDefenceData() 
			return Localize.village_name[village_data.name] .. "Lv" .. village_data.level
		elseif self:WithObject():MarchType() == 'shrine' then
			return _("圣地")
		elseif self:WithObject():MarchType() == 'monster' then
			return self:WithObject():GetTargetName()
		end
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_RETURN  
		or self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN then

			return self:WithObject():AttackPlayerData().name
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		return _("圣地")
	end
end

function BelvedereEntity:GetDestinationLocation()
	
	if self:GetType() == self.ENTITY_TYPE.COLLECT then
		local location = self:WithObject():TargetLocation()
		return location.x .. "," .. location.y
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT  
		or self:GetType() == self.ENTITY_TYPE.MARCH_RETURN 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_OUT 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN 
		then
		local location = self:WithObject():TargetLocation()
		return location.x .. "," .. location.y
	elseif self:GetType() == self.ENTITY_TYPE.HELPTO then
		return self:WithObject().beHelpedPlayerData.location.x .. "," .. self:WithObject().beHelpedPlayerData.location.y
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		-- local location =  self:FindShrinePlayerTroops().location
		-- return location.x .. "," .. location.y
		local map_obj = Alliance_Manager:GetMyAlliance():GetAllianceShrine():GetShireObjectFromMap()
		local x,y = map_obj:GetLogicPosition()
		return string.format("%d,%d",x,y)
	end
end

function BelvedereEntity:GetDestinationLocationNotString()
	if self:GetType() == self.ENTITY_TYPE.COLLECT then
		return self:WithObject():TargetLocation()
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT  
		or self:GetType() == self.ENTITY_TYPE.MARCH_RETURN 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_OUT 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN 
		then
		return self:WithObject():TargetLocation()
	elseif self:GetType() == self.ENTITY_TYPE.HELPTO then
		return self:WithObject().beHelpedPlayerData.location
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		local map_obj = Alliance_Manager:GetMyAlliance():GetAllianceShrine():GetShireObjectFromMap()
		local x,y = map_obj:GetLogicPosition()
		return {x = x,y = y}
	end
end

function BelvedereEntity:GetDragonType()
	if self:GetType() == self.ENTITY_TYPE.HELPTO then
		return self:WithObject().playerDragon
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT  
		or self:GetType() == self.ENTITY_TYPE.MARCH_RETURN 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_OUT 
		or self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN 
		then
		return self:WithObject():AttackPlayerData().dragon.type
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		return self:FindShrinePlayerTroops().dragon.type
	end
end

function BelvedereEntity:FindShrinePlayerTroops()
	if  self:GetType() == self.ENTITY_TYPE.SHIRNE then 
		local troops = self:WithObject():PlayerTroops()
		for _,v in ipairs(troops) do
			if v.id == User:Id() then
				return v
			end
		end

	end
end

function BelvedereEntity:GetFromCityName()
	if self:GetType() == self.ENTITY_TYPE.MARCH_OUT  
		or self:GetType() == self.ENTITY_TYPE.STRIKE_OUT 
		or self:GetType() == self.ENTITY_TYPE.HELPTO 
		then
		return self:WithObject():AttackPlayerData().name
	end
end

function BelvedereEntity:GetAttackPlayerName()
	if self:GetType() == self.ENTITY_TYPE.MARCH_OUT  
		or self:GetType() == self.ENTITY_TYPE.STRIKE_OUT 
		or self:GetType() == self.ENTITY_TYPE.HELPTO 
		then
		return self:WithObject():AttackPlayerData().name
	end
end
--获取事件的服务器类型标识字符串
function BelvedereEntity:GetEventServerType()
	if self:GetType() == self.ENTITY_TYPE.HELPTO then
		return  "attackMarchEvents"
	elseif self:GetType() == self.ENTITY_TYPE.COLLECT then
		return "村落采集事件"
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_OUT then
		return "attackMarchEvents"
	elseif self:GetType() == self.ENTITY_TYPE.MARCH_RETURN then
		return "attackMarchReturnEvents"
	elseif self:GetType() == self.ENTITY_TYPE.STRIKE_OUT then
		return "strikeMarchEvents"
	elseif self:GetType() == self.ENTITY_TYPE.STRIKE_RETURN then
		return "strikeMarchReturnEvents"
	elseif self:GetType() == self.ENTITY_TYPE.SHIRNE then
		return "圣地事件"
	end
end
return BelvedereEntity
