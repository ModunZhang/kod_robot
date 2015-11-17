UtilsForShrine = {}
function UtilsForShrine:GetEventTime(event)
	return event.startTime/1000 - app.timer:GetServerTime()
end



local ShrinePlayFightReport = class("ShrinePlayFightReport")
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
	self:formatOrderedAttackSoldiers()
end

function ShrinePlayFightReport:formatOrderedAttackSoldiers()
	local result = {}
	self.orderedAttackSoldiers = {}
	for index,v in ipairs(self.fightAttackSoldierRoundData) do
		if not result[v.soldierName] then
			result[v.soldierName] = {name = v.soldierName,star = v.soldierStar,count = v.soldierCount or 0,index = index}
		end
	end
	for ___,v in pairs(result) do
		table.insert(self.orderedAttackSoldiers,v)
	end
	table.sort( self.orderedAttackSoldiers, function(a,b)
		return a.index < b.index
	end)

	result = {}
	self.orderedDefenceSoldierRoundData = {}
	for index,v in ipairs(self.fightDefenceSoldierRoundData) do
		if not result[v.soldierName] then
			result[v.soldierName] = {name = v.soldierName,star = v.soldierStar,count = v.soldierCount or 0,index = index}
		end
	end
	for ___,v in pairs(result) do
		table.insert(self.orderedDefenceSoldierRoundData,v)
	end
	table.sort( self.orderedDefenceSoldierRoundData, function(a,b)
		return a.index < b.index
	end)
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
   return self.orderedAttackSoldiers or {}
end
function ShrinePlayFightReport:GetOrderedDefenceSoldiers()
   return self.orderedDefenceSoldierRoundData or {}
end
function ShrinePlayFightReport:GetReportResult()
	return self.isWin
end
function ShrinePlayFightReport:GetAttackDragonLevel()
	return self.attackDragonRoundData.level
end

function ShrinePlayFightReport:GetAttackTargetTerrain()
	return Alliance_Manager:GetMyAlliance().basicInfo.terrain
end

function ShrinePlayFightReport:IsAttackCamp()
	return true
end
function ShrinePlayFightReport:GetDefenceDragonLevel()
	return self.defenceDragonRoundData.level
end

function UtilsForShrine:GetFightReport(report)
	local shrinePlayFightReport = ShrinePlayFightReport.new(
		report.playerName,
		Localize.shrine_desc[report.stageName][1],
		report.attackDragonFightData,
		report.defenceDragonFightData,
		report.attackSoldierRoundDatas,
		report.defenceSoldierRoundDatas,
		report.fightResult == "attackWin"
	)
	return shrinePlayFightReport
end

function UtilsForShrine:FormatShrineTroops(stageinfo)
	local r = {}
	local troops_temp = string.split(stageinfo.troops,",")
	for i,suntroops in ipairs(troops_temp) do
		local troops = string.split(suntroops,"_")
		local troop_type,star = troops[1],troops[2]
		local count =  checknumber(troops[3])
		local count_str = math.ceil(count*0.9) * stageinfo.suggestPlayer .. "~" .. math.ceil(count*1.1)* stageinfo.suggestPlayer
		table.insert(r,{type = troop_type,count = count_str,star = tonumber(star)})
	end
	return r
end

function UtilsForShrine:FormatShrineRewards(stageinfo, index, terrain)
	assert(type(index) == "number")
	assert(type(terrain) == "string")
	local key = string.format("playerRewards_%s_%s", index, terrain)
	local r = {}
	local reward_list = string.split(stageinfo[key], ",")
	for i,v in ipairs(reward_list) do
		local reward_type,sub_type,count = unpack(string.split(v,":"))
		table.insert(r,{type = reward_type,sub_type = sub_type,count = count})
	end
	return r
end