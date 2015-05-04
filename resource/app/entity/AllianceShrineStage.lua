--
-- Author: Danny He
-- Date: 2014-11-07 17:09:04
--
-- 联盟圣地关卡
local AllianceShrineStage = class("AllianceShrineStage")
local property = import("..utils.property")


function AllianceShrineStage:ctor(config)
	property(self,"isLocked",true)
	self.config_ = config
	self:loadProperty(config)
end

function AllianceShrineStage:loadProperty(config)
	property(self,"stageName",config.stageName)
	property(self,"stage",config.stage)
	property(self,"maxStar",3) -- 最大3星
	property(self,"subStage",config.subStage)
	property(self,"enemyPower",config.enemyPower)
	property(self,"index",config.index)
	property(self,"needPerception",config.needPerception)
	property(self,"suggestPlayer",config.suggestPlayer)
	property(self,"suggestPower",config.suggestPower)
	self:formatTroops(config.troops)
	property(self,"star2DeathCitizen",config.star2DeathCitizen)
	property(self,"star1Honour",config.star1Honour)
	property(self,"star2Honour",config.star2Honour)
	property(self,"star3Honour",config.star3Honour)
	property(self,"bronzeKill",config.playerKill_1)
	property(self,"silverKill",config.playerKill_2)
	property(self,"goldKill",config.playerKill_3)
end

function AllianceShrineStage:OnPropertyChange()
end

function AllianceShrineStage:GetDescStageName()
	return string.gsub(self:StageName(),'_','-') .. " 本地化缺失"
end

function AllianceShrineStage:GetStageDesc()
	return "关卡描述" .. self:StageName() .. "本地化缺失"
end

function AllianceShrineStage:Reset()
	self:SetIsLocked(true)
	self:SetStar(0)
end

--兵数量上下浮动20%
function AllianceShrineStage:formatTroops(str)
	local r = {}
	local troops_temp = string.split(str,",")
	for i,suntroops in ipairs(troops_temp) do
		local troops = string.split(suntroops,"_")
		local troop_type,star = troops[1],troops[2]
		local count =  checknumber(troops[3])
		local count_str = math.ceil(count*0.8) .. "-" .. math.ceil(count*1.2)
		table.insert(r,{type = troop_type,count = count_str,star = tonumber(star)})
	end
	property(self,"troops",r)
end

function AllianceShrineStage:formatRewards(rewards)
	local r = {}
	local reward_list = string.split(rewards,",")
	for i,v in ipairs(reward_list) do
		local reward_type,sub_type,count = unpack(string.split(v,":"))
		table.insert(r,{type = reward_type,sub_type = sub_type,count = count})
	end
	return r
end

function AllianceShrineStage:SetStar(star)
	if star >= 0 and  self:MaxStar() >= star then
		self.star_ = star
	end
end

function AllianceShrineStage:BronzeRewards(terrain)
	if terrain then
		local key = string.format("playerRewards_1_%s",terrain)
		return self:formatRewards(self.config_[key])
	end
	return {}
end

function AllianceShrineStage:SilverRewards(terrain)
	if terrain then
		local key = string.format("playerRewards_2_%s",terrain)
		return self:formatRewards(self.config_[key])
	end
	return {}
end

function AllianceShrineStage:GoldRewards(terrain)
	if terrain then
		local key = string.format("playerRewards_3_%s",terrain)
		return self:formatRewards(self.config_[key])
	end
	return {}
end

function AllianceShrineStage:Star()
	return self.star_ or 0
end

return AllianceShrineStage