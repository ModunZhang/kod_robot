--
-- Author: Danny He
-- Date: 2014-11-17 17:52:09
--
local ShrineReport = class("ShrineReport")
local property = import("..utils.property")
local ShrinePlayFightReport = class("ShrinePlayFightReport")
function ShrineReport:ctor()
	property(self,"id","")
	property(self,"star",0)
	property(self,"time",0)
	property(self,"stageName","")
	property(self,"fightDatas",{})
	property(self,"playerDatas",{})
	property(self,"playerAvgPower",{})
	property(self,"playerCount",{})
	property(self,"stage",{}) -- will be set in
	                     
end

function ShrineReport:OnPropertyChange()
end

function ShrineReport:Update(json_data)
	self:SetId(json_data.id)
	self:SetStar(json_data.star)
	self:SetStageName(json_data.stageName)
	self:SetFightDatas(json_data.fightDatas)
	self:SetPlayerDatas(json_data.playerDatas)
	self:SetPlayerAvgPower(json_data.playerAvgPower)
	self:SetPlayerCount(json_data.playerCount)
	self:SetTime(json_data.time and json_data.time/1000 or 0)
end

--获取相应星级的声望奖励
function ShrineReport:GetHonour()
	if self:Stage() then
		return self:Stage()["star" .. self:Star() .. "Honour"]
	end
end

function ShrineReport:GetFightReportObjectWithJson(json_data)
	local shrinePlayFightReport = ShrinePlayFightReport.new(
		json_data.playerName,
		self:Stage():GetDescStageName(),
		json_data.attackDragonFightData,
		json_data.defenceDragonFightData,
		json_data.attackSoldierRoundDatas,
		json_data.defenceSoldierRoundDatas,
		json_data.fightResult == "attackWin"
	)
	return shrinePlayFightReport
end

-- 战斗回放相关获取数据方法
function ShrinePlayFightReport:ctor(attackName,defenceName,attackDragonRoundData,defenceDragonRoundData,fightAttackSoldierRoundData,fightDefenceSoldierRoundData,isWin)
	self.attackName = attackName
	self.defenceName = defenceName
	self.attackDragonRoundData = attackDragonRoundData
	self.defenceDragonRoundData = defenceDragonRoundData
	self.fightAttackSoldierRoundData = fightAttackSoldierRoundData
	self.fightDefenceSoldierRoundData = fightDefenceSoldierRoundData
	self.isWin = isWin
	for __,v in ipairs(fightAttackSoldierRoundData) do
		v.name = v.soldierName
		v.star = v.soldierStar
		v.count = v.soldierCount
	end
	for __,v in ipairs(fightDefenceSoldierRoundData) do
		v.name = v.soldierName
		v.star = v.soldierStar
		v.count = v.soldierCount
	end
end


function ShrinePlayFightReport:GetFightAttackName()
  	return self.attackName
end
function ShrinePlayFightReport:GetFightDefenceName()
   	return self.defenceName
end
function ShrinePlayFightReport:IsDragonFight()
 	return true
end
function ShrinePlayFightReport:GetFightAttackDragonRoundData()
 	return self.attackDragonRoundData or {}
end
function ShrinePlayFightReport:GetFightDefenceDragonRoundData()
   	return self.defenceDragonRoundData or {}
end
function ShrinePlayFightReport:GetFightAttackSoldierRoundData()
    return self.fightAttackSoldierRoundData or {}
end
function ShrinePlayFightReport:GetFightDefenceSoldierRoundData()
    return self.fightDefenceSoldierRoundData or {}
end
function ShrinePlayFightReport:IsFightWall()
  	return false 
end
function ShrinePlayFightReport:GetFightAttackWallRoundData()
   	return {}
end
function ShrinePlayFightReport:GetFightDefenceWallRoundData()
    return {}
end
function ShrinePlayFightReport:GetOrderedAttackSoldiers()
   return self.fightAttackSoldierRoundData or {}
end
function ShrinePlayFightReport:GetOrderedDefenceSoldiers()
   return self.fightDefenceSoldierRoundData or {}
end
function ShrinePlayFightReport:GetReportResult()
	return self.isWin
end
function ShrinePlayFightReport:GetAttackDragonLevel()
	return self.attackDragonRoundData.level
end

function ShrinePlayFightReport:GetAttackTargetTerrain()
	return Alliance_Manager:GetMyAlliance():Terrain()
end

function ShrinePlayFightReport:GetDefenceDragonLevel()
	return self.defenceDragonRoundData.level
end
return ShrineReport