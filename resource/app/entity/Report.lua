local Enum = import("..utils.Enum")
local property = import("..utils.property")
local Localize = import("..utils.Localize")


local Report = class("Report")
property(Report, "id", "")
property(Report, "type", "")
property(Report, "createTime", 0)
property(Report, "isRead", false)
property(Report, "isSaved", false)
property(Report, "index", 0)
Report.REPORT_TYPE = Enum("strikeCity","cityBeStriked","strikeVillage","villageBeStriked","attackCity","attackVillage","collectResource","attackMonster","attackShrine")
local STRIKECITY,CITYBESTRIKED,STRIKEVILLAGE,VILLAGEBESTRIKED,ATTACKCITY,ATTACKVILLAGE,COLLECTRESOURCE,ATTACKMONSTER,ATTACKSHRINE = 1,2,3,4,5,6,7,8,9
function Report:ctor(id,type,createTime,isRead,isSaved,index)
    self:SetId(id)
    self:SetType(type)
    self:SetCreateTime(createTime)
    self:SetIsRead(isRead)
    self:SetIsSaved(isSaved)
    self:SetIndex(index)
    self.player_id = User:Id()
end
function Report:OnPropertyChange(property_name, old_value, new_value)

end
function Report:DecodeFromJsonData(json_data)
    local report = Report.new(json_data.id, json_data.type, json_data.createTime, json_data.isRead, json_data.isSaved,json_data.index)
    report:SetData(json_data[json_data.type])
    return report
end
function Report:SetPlayerId( player_id )
    self.player_id = player_id
end
function Report:Update( json_data )
    self:SetIsRead(json_data.isRead)
    self:SetIsSaved(json_data.isSaved)
end
function Report:SetData(data)
    local function replace_null_to_nil(t)
        for k,v in pairs(t) do
            if v == json.null then
                t[k] = nil
            elseif tolua.type(v) == "table" then
                replace_null_to_nil(v)
            end
        end
    end
    replace_null_to_nil(data)
    self.data = data
end
function Report:GetData()
    return self.data
end
-- 进攻玩家城市战报api BEGIN --
function Report:IsRenamed()
    local data = self:GetData()
    return data.isRenamed
end
function Report:GetAttackTarget()
    local data = self:GetData()
    return data.attackTarget
end
function Report:GetMyPlayerData()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.attackPlayerData
    else
        return data.helpDefencePlayerData or data.defencePlayerData or data.defenceVillageData
    end
end
function Report:GetEnemyPlayerData()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.helpDefencePlayerData or data.defencePlayerData or data.defenceVillageData or data.defenceMonsterData
    else
        return data.attackPlayerData
    end
end
function Report:GetShrineRoundDatas()
    local data = self:GetData()
    return data.roundDatas
end
function Report:GetMyHelpFightTroop()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        if data.attackPlayerData.fightWithHelpDefenceTroop then
            return data.attackPlayerData.fightWithHelpDefenceTroop.soldiers
        end
    else
        if data.helpDefencePlayerData then
            return data.helpDefencePlayerData.soldiers
        end
    end
end
function Report:GetEnemyHelpFightTroop()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        if data.helpDefencePlayerData then
            return data.helpDefencePlayerData.soldiers
        end
    else
        if data.attackPlayerData.fightWithHelpDefenceTroop then
            return data.attackPlayerData.fightWithHelpDefenceTroop.soldiers
        end
    end
end
function Report:GetMyHelpFightDragon()
    local data = self:GetData()
    if self.type == Report.REPORT_TYPE[ATTACKCITY] then
        if self.player_id == data.attackPlayerData.id then
            if data.attackPlayerData.fightWithHelpDefenceTroop then
                return data.attackPlayerData.fightWithHelpDefenceTroop.dragon
            end
        else
            if data.helpDefencePlayerData then
                return data.helpDefencePlayerData.dragon
            end
        end
    elseif self.type == Report.REPORT_TYPE[CITYBESTRIKED] or
        self.type == Report.REPORT_TYPE[STRIKECITY]
    then
        if self.player_id == data.attackPlayerData.id then
            if data.attackPlayerData.dragon then
                return data.attackPlayerData.dragon
            end
        else
            if data.helpDefencePlayerData then
                return data.helpDefencePlayerData.dragon
            end
        end
    end
end
function Report:GetEnemyHelpFightDragon()
    local data = self:GetData()
    if self.type == Report.REPORT_TYPE[ATTACKCITY] then
        if self.player_id == data.attackPlayerData.id then
            if data.helpDefencePlayerData then
                return data.helpDefencePlayerData.dragon
            end
        else
            if data.attackPlayerData.fightWithHelpDefenceTroop then
                return data.attackPlayerData.fightWithHelpDefenceTroop.dragon
            end
        end
    elseif self.type == Report.REPORT_TYPE[CITYBESTRIKED] or
        self.type == Report.REPORT_TYPE[STRIKECITY]
    then
        if self.player_id == data.attackPlayerData.id then
            if data.helpDefencePlayerData then
                return data.helpDefencePlayerData.dragon
            end
        else
            if data.attackPlayerData then
                return data.attackPlayerData.dragon
            end
        end
    end
end
function Report:GetMyDefenceFightTroop()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.attackPlayerData.fightWithDefenceTroop and data.attackPlayerData.fightWithDefenceTroop.soldiers
            or data.attackPlayerData and data.attackPlayerData.soldiers
    else
        return data.defencePlayerData and data.defencePlayerData.soldiers
            or data.defenceVillageData and data.defenceVillageData.soldiers
    end
end
function Report:GetEnemyDefenceFightTroop()
    local data = self:GetData()

    if self.player_id == data.attackPlayerData.id then
        return data.defencePlayerData and data.defencePlayerData.soldiers
            or data.defenceVillageData and data.defenceVillageData.soldiers
            or data.defenceMonsterData and data.defenceMonsterData.soldiers
    else
        return data.attackPlayerData and data.attackPlayerData.soldiers or data.attackPlayerData.fightWithDefenceTroop and data.attackPlayerData.fightWithDefenceTroop.soldiers
    end
end
function Report:GetMyDefenceFightDragon()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.attackPlayerData.fightWithDefenceTroop and data.attackPlayerData.fightWithDefenceTroop.dragon
            or data.attackPlayerData and data.attackPlayerData.dragon
    else
        return data.defencePlayerData and data.defencePlayerData.dragon
            or data.defenceVillageData and data.defenceVillageData.dragon
    end
end
function Report:GetEnemyDefenceFightDragon()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.defencePlayerData and data.defencePlayerData.dragon
            or data.defenceVillageData and data.defenceVillageData.dragon
            or data.defenceMonsterData and data.defenceMonsterData.dragon
    else
        return data.attackPlayerData.fightWithDefenceTroop and data.attackPlayerData.fightWithDefenceTroop.dragon
            or data.attackPlayerData and data.attackPlayerData.dragon
    end
end

function Report:GetMyRoundDatas()
    local data = self:GetData()
    local round_datas = {}
    local soldierRoundDatas, wallRoundDatas
    if self.player_id == data.attackPlayerData.id then
        if data.fightWithHelpDefencePlayerReports then
            soldierRoundDatas = data.fightWithHelpDefencePlayerReports.soldierRoundDatas
        end
        if data.fightWithDefencePlayerReports then
            soldierRoundDatas = data.fightWithDefencePlayerReports.soldierRoundDatas
            if data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas then
                wallRoundDatas = data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas
            end
        end
        if data.fightWithDefenceVillageReports then
            soldierRoundDatas = data.fightWithDefenceVillageReports.soldierRoundDatas
        end
        if data.fightWithDefenceMonsterReports then
            soldierRoundDatas = data.fightWithDefenceMonsterReports.soldierRoundDatas
        end
        if soldierRoundDatas then
            for i,round in ipairs(soldierRoundDatas) do
                for i,attack in ipairs(round.attackResults) do
                    table.insert(round_datas, attack)
                end
            end
        end
        if wallRoundDatas then
            for i,attack in ipairs(wallRoundDatas) do
                table.insert(round_datas, attack)
            end
        end
    else
        if data.fightWithHelpDefencePlayerReports then
            soldierRoundDatas = data.fightWithHelpDefencePlayerReports.soldierRoundDatas
        end
        if data.fightWithDefencePlayerReports then
            soldierRoundDatas = data.fightWithDefencePlayerReports.soldierRoundDatas
        end
        if soldierRoundDatas then
            for i,round in ipairs(soldierRoundDatas) do
                for i,defence in ipairs(round.defenceResults) do
                    table.insert(round_datas, defence)
                end
            end
        end
    end

    return round_datas
end
function Report:GetEnemyRoundDatas()
    local data = self:GetData()
    local round_datas = {}
    local soldierRoundDatas, wallRoundDatas
    if self.player_id == data.attackPlayerData.id then
        if data.fightWithHelpDefencePlayerReports then
            soldierRoundDatas = data.fightWithHelpDefencePlayerReports.soldierRoundDatas
        end
        if data.fightWithDefencePlayerReports then
            soldierRoundDatas = data.fightWithDefencePlayerReports.soldierRoundDatas
        end
        if data.fightWithDefenceMonsterReports then
            soldierRoundDatas = data.fightWithDefenceMonsterReports.soldierRoundDatas
        end
        if soldierRoundDatas then
            for i,round in ipairs(soldierRoundDatas) do
                for i,defence in ipairs(round.defenceResults) do
                    table.insert(round_datas, defence)
                end
            end
        end
    else
        if data.fightWithHelpDefencePlayerReports then
            soldierRoundDatas = data.fightWithHelpDefencePlayerReports.soldierRoundDatas
        end
        if data.fightWithDefencePlayerReports then
            soldierRoundDatas = data.fightWithDefencePlayerReports.soldierRoundDatas
            if data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas then
                wallRoundDatas = data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas
            end
        end
        if data.fightWithDefenceVillageReports then
            soldierRoundDatas = data.fightWithDefenceVillageReports.soldierRoundDatas
        end
        if soldierRoundDatas then
            for i,round in ipairs(soldierRoundDatas) do
                for i,attack in ipairs(round.attackResults) do
                    table.insert(round_datas, attack)
                end
            end
        end
        if wallRoundDatas then
            for i,attack in ipairs(wallRoundDatas) do
                table.insert(round_datas, attack)
            end
        end
    end
    return round_datas
end
function Report:GetMyRewards()
    local data = self:GetData()
    if data.attackPlayerData and data.attackPlayerData.id == self.player_id then
        return data.attackPlayerData.rewards
    elseif data.helpDefencePlayerData and data.helpDefencePlayerData.id == self.player_id then
        return data.helpDefencePlayerData.rewards
    elseif data.defencePlayerData and data.defencePlayerData.id == self.player_id then
        return data.defencePlayerData.rewards
    elseif self.type == Report.REPORT_TYPE[COLLECTRESOURCE] or self.type == Report.REPORT_TYPE[ATTACKSHRINE] then
        return data.rewards
    end
end
function Report:GetWallData()
    local data = self:GetData()
    if data.defencePlayerData and data.defencePlayerData.wall then
        return {
            wall = data.defencePlayerData.wall,
            soldiers = data.attackPlayerData.fightWithDefenceWall.soldiers
        }
    end
end
function Report:IsAttackCamp()
    local data = self:GetData()
    return data.attackPlayerData.id == self.player_id
end
-- 进攻玩家城市战报api END --


-- 突袭战报api BEGIN --
function Report:GetStrikeLevel()
    local data = self:GetData()
    return data.level
end
function Report:GetStrikeTarget()
    local data = self:GetData()

    return data.strikeTarget
end
-- 获取突袭情报的对象
function Report:GetStrikeIntelligence()
    assert(self.type == Report.REPORT_TYPE[CITYBESTRIKED] or Report.REPORT_TYPE[STRIKECITY] or Report.REPORT_TYPE[STRIKEVILLAGE] or Report.REPORT_TYPE[VILLAGEBESTRIKED],"非突袭战报")
    local data = self:GetData()
    if data.helpDefencePlayerData then
        return data.helpDefencePlayerData
    elseif data.defenceVillageData then
        return data.defenceVillageData
    elseif data.defencePlayerData then
        return data.defencePlayerData
    end
end
-- 突袭战报api END --

function Report:GetBattleAt()
    local data = self:GetData()
    if self.type == Report.REPORT_TYPE[CITYBESTRIKED]
        or self.type == Report.REPORT_TYPE[STRIKECITY]
    then
        return data.strikeTarget.name
    elseif self.type == Report.REPORT_TYPE[ATTACKCITY] then
        return data.attackTarget.name
    elseif self.type == Report.REPORT_TYPE[VILLAGEBESTRIKED]
        or self.type == Report.REPORT_TYPE[STRIKEVILLAGE]
    then
        return Localize.village_name[data.strikeTarget.name]
    elseif self.type == Report.REPORT_TYPE[ATTACKVILLAGE] then
        return Localize.village_name[data.attackTarget.name]
    elseif self.type == Report.REPORT_TYPE[COLLECTRESOURCE] then
        return Localize.village_name[data.collectTarget.name]
    elseif self.type == Report.REPORT_TYPE[ATTACKMONSTER] then
        return data.attackTarget.level
    end
end
function Report:GetBattleLocation()
    local data = self:GetData()
    if self.type == Report.REPORT_TYPE[CITYBESTRIKED]
        or self.type == Report.REPORT_TYPE[STRIKECITY]
        or self.type == Report.REPORT_TYPE[VILLAGEBESTRIKED]
        or self.type == Report.REPORT_TYPE[STRIKEVILLAGE] then
        return data.strikeTarget.location
    elseif self.type == Report.REPORT_TYPE[ATTACKCITY]
        or self.type == Report.REPORT_TYPE[ATTACKVILLAGE]
        or self.type == Report.REPORT_TYPE[ATTACKMONSTER]
        or self.type == Report.REPORT_TYPE[ATTACKSHRINE]
    then
        return data.attackTarget.location
    elseif self.type == Report.REPORT_TYPE[COLLECTRESOURCE] then
        return data.collectTarget.location
    end
end

function Report:GetReportTitle()
    local data = self:GetData()
    local report_type = self.type
    if report_type == "strikeCity" then
        if data.level>1 then
            return _("突袭成功")
        else
            return _("突袭失败")
        end
    elseif report_type == "strikeVillage" then
        if data.level>1 then
            return _("突袭村落成功")
        else
            return _("突袭村落失败")
        end
    elseif report_type== "cityBeStriked" then
        if data.level>1 then
            return _("防守突袭失败")
        else
            return _("防守突袭成功")
        end
    elseif report_type == "villageBeStriked" then
        if data.level>1 then
            return _("防守突袭村落失败")
        else
            return _("防守突袭村落成功")
        end
    elseif report_type=="attackCity" then
        local result = self:GetReportResult()
        if data.attackPlayerData.id == self.player_id then
            if data.fightWithHelpDefencePlayerReports then
                return result and _("进攻协防部队成功") or _("进攻协防部队失败")
            elseif data.fightWithDefencePlayerReports then
                return result and _("进攻城市成功") or _("进攻城市失败")
            else
                return _("进攻城市成功")
            end
        elseif data.defencePlayerData and data.defencePlayerData.id == self.player_id then
            return result and _("防守城市成功") or _("防守城市失败")
        elseif data.helpDefencePlayerData and
            data.helpDefencePlayerData.id == self.player_id then
            return result and _("协助防守城市成功") or _("协助防守城市失败")
        end
    elseif report_type=="attackVillage" then
        local result = self:GetReportResult()
        if data.attackPlayerData.id == self.player_id then
            return result and _("占领村落成功") or _("占领村落失败")
        elseif data.defencePlayerData and data.defencePlayerData.id == self.player_id then
            return result and _("防守村落成功") or _("防守村落失败")
        end
    elseif report_type=="collectResource" then
        return _("采集报告")
    elseif report_type=="attackMonster" then
        local result = self:GetReportResult()
        return result and _("进攻黑龙军团成功") or _("进攻黑龙军团失败")
    elseif report_type=="attackShrine" then
        return self:GetAttackTarget().isWin and _("攻打联盟圣地成功") or _("攻打联盟圣地失败")
    end
end
function Report:IsFromMe()
    local data = self:GetData()
    local report_type = self.type
    if report_type == "strikeCity" then
        return true
    elseif report_type=="strikeVillage" or report_type=="attackVillage" then
        return data.attackPlayerData.id == self.player_id
    elseif report_type=="villageBeStriked"
        or report_type=="cityBeStriked" then
        return false
    elseif report_type=="attackCity" then
        return data.attackTarget.id ~= self.player_id
    elseif report_type=="collectResource" then
        return "collectResource"
    elseif report_type=="attackMonster" then
        return "attackMonster"
    elseif report_type=="attackShrine" then
        return "attackShrine"
    end
end
function Report:IsAttackOrStrike()
    local data = self:GetData()
    local report_type = self.type
    if report_type == "strikeCity"
        or report_type=="strikeVillage"
        or report_type=="villageBeStriked"
        or report_type=="cityBeStriked" then
        return "strike"
    elseif report_type=="attackCity"
        or report_type=="attackVillage" then
        return "attack"
    elseif report_type=="collectResource" then
        return "collect"
    elseif report_type=="attackMonster" then
        return "strike"
    elseif report_type=="attackShrine" then
        return "strike"
    end
end
function Report:IsWin()
    local data = self:GetData()
    local report_type = self.type
    if report_type == "strikeCity" then
        if data.level>1 then
            return true
        else
            return false
        end
    elseif report_type == "strikeVillage" then
        if data.level>1 then
            return _("突袭村落成功")
        else
            return false
        end
    elseif report_type== "cityBeStriked" then
        if data.level>1 then
            return false
        else
            return _("防守突袭成功")
        end
    elseif report_type == "villageBeStriked" then
        if data.level>1 then
            return _("防守突袭村落成功")
        else
            return false
        end
    elseif report_type=="attackCity" then
        return self:GetReportResult()
    elseif report_type=="attackVillage" then
        return self:GetReportResult()
    elseif report_type=="collectResource" then
        return true
    elseif report_type=="attackMonster" then
        return self:GetReportResult()
    elseif report_type=="attackShrine" then
        return self:GetAttackTarget().isWin
    end
end
function Report:IsHasHelpDefencePlayer()
    local data = self:GetData()
    return data.helpDefencePlayerData
end

-- 战斗回放相关获取数据方法
function Report:GetFightAttackName()
    local data = self:GetData()
    return data.attackPlayerData.name
end
function Report:GetFightDefenceName()
    local data = self:GetData()
    return data.helpDefencePlayerData and data.helpDefencePlayerData.name
        or data.defencePlayerData and data.defencePlayerData.name
        or data.defenceMonsterData and Localize.soldier_name[data.defenceMonsterData.soldiers[1].name]
end
function Report:IsDragonFight()
    local data = self:GetData()
    local dragonFightData = data.fightWithHelpDefencePlayerReports or
        data.fightWithDefencePlayerReports or
        data.fightWithDefenceMonsterReports
    local isFight = false
    if dragonFightData and dragonFightData.attackPlayerDragonFightData and dragonFightData.attackPlayerDragonFightData ~= json.null then
        isFight = true
    end
    return isFight
end
function Report:CouldAttackDragonUseSkill()
    local dragonData = self:GetFightAttackDragonRoundData()
    return dragonData.hp - dragonData.hpDecreased > 0
end
function Report:CouldDefenceDragonUseSkill()
    local dragonData = self:GetFightDefenceDragonRoundData()
    return dragonData.hp - dragonData.hpDecreased > 0
end
function Report:GetFightAttackDragonRoundData()
    local data = self:GetData()
    if not self:IsDragonFight() then
        return {}
    end
    local dragonFightData = data.fightWithHelpDefencePlayerReports or
        data.fightWithDefencePlayerReports or
        data.fightWithDefenceMonsterReports
    return dragonFightData.attackPlayerDragonFightData
end
function Report:GetFightDefenceDragonRoundData()
    local data = self:GetData()
    if not self:IsDragonFight() then
        return {}
    end
    local dragonFightData = data.fightWithHelpDefencePlayerReports or
        data.fightWithDefencePlayerReports or
        data.fightWithDefenceMonsterReports
    return dragonFightData.defencePlayerDragonFightData or dragonFightData.defenceMonsterDragonFightData
end
function Report:IsSoldierFight()
    local data = self:GetData()
    local fightReports = data.fightWithHelpDefencePlayerReports or
        data.fightWithDefencePlayerReports or
        data.fightWithDefenceMonsterReports
    if not fightReports then
        return
    end
    return fightReports.soldierRoundDatas and not LuaUtils:table_empty(fightReports.soldierRoundDatas)
end
function Report:GetOrderedAttackSoldiers()
    local attackPlayerData = self:GetData().attackPlayerData
    local troop = attackPlayerData.fightWithHelpDefenceTroop or attackPlayerData.fightWithDefenceTroop or attackPlayerData.fightWithDefenceWall
    local soldiers = troop and  troop.soldiers or attackPlayerData.soldiers or {}
    return soldiers
end
function Report:GetOrderedDefenceSoldiers()
    local data = self:GetData()
    local defenceData = data.helpDefencePlayerData or data.defencePlayerData or data.defenceMonsterData
    local soldiers = defenceData and defenceData.soldiers or {}
    return soldiers
end
function Report:GetSoldierRoundData()
    if not self:IsSoldierFight() then
        return {}
    end
    local data = self:GetData()
    local fightData = data.fightWithHelpDefencePlayerReports or
        data.fightWithDefencePlayerReports or
        data.fightWithDefenceMonsterReports
    return fightData.soldierRoundDatas
end

function Report:IsFightWall()
    local data = self:GetData()
    local isFight = false
    if data.fightWithDefencePlayerReports and data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas and #data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas > 0 then
        isFight = true
    end
    return isFight
end
function Report:IsFightWithBlackTroops()
    return self:Type() == "attackMonster"
end
function Report:GetFightAttackWallRoundData()
    if not self:IsFightWall() then
        return {}
    end
    local data = self:GetData()
    return data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas
end
function Report:GetFightDefenceWallRoundData()
    if not self:IsFightWall() then
        return {}
    end
    local data = self:GetData()
    return data.fightWithDefencePlayerReports.defencePlayerWallRoundDatas
end

function Report:GetFightReports()
    local data = self:GetData()
    return data.fightWithHelpDefencePlayerReports or data.fightWithDefencePlayerReports or data.fightWithDefenceMonsterReports
        or {}
end
function Report:GetReportResult()
    local data = self.data
    if data.attackPlayerData.id == self.player_id then
        if data.fightWithHelpDefencePlayerReports then
            local my_round = data.fightWithHelpDefencePlayerReports.soldierRoundDatas
            local isWin = true
            for i,v in ipairs(my_round[#my_round].attackResults) do
                isWin = isWin and v.isWin
            end
            return isWin
        elseif data.fightWithDefencePlayerReports then
            -- 打到城墙，直接算赢
            local wall_round = data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas
            if wall_round then
                return true
            end
            local my_round = data.fightWithDefencePlayerReports.soldierRoundDatas
            local isWin = true
            for i,v in ipairs(my_round[#my_round].attackResults) do
                isWin = isWin and v.isWin
            end
            return isWin
        elseif data.fightWithDefenceMonsterReports then
            local my_round = data.fightWithDefenceMonsterReports.soldierRoundDatas
            local isWin = true
            for i,v in ipairs(my_round[#my_round].attackResults) do
                isWin = isWin and v.isWin
            end
            return isWin
        else
            return true
        end
    elseif data.defencePlayerData and data.defencePlayerData.id == self.player_id then
        -- 完全没有战斗数据,表示防守玩家城墙血量为零，且没有驻防
        if not data.fightWithDefencePlayerReports then
            return false
        end
        -- 打到城墙，直接算输
        local wall_round = data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas
        if wall_round then
            return false
        end
        local my_round = data.fightWithDefencePlayerReports.soldierRoundDatas
        local isWin = true
        for i,v in ipairs(my_round[#my_round].defenceResults) do
            isWin = isWin and v.isWin
        end
        return isWin
    elseif data.helpDefencePlayerData and
        data.helpDefencePlayerData.id == self.player_id then
        local my_round = data.fightWithHelpDefencePlayerReports.soldierRoundDatas
        local isWin = true
        for i,v in ipairs(my_round[#my_round].defenceResults) do
            isWin = isWin and v.isWin
        end
        return isWin
    end
end
function Report:GetAttackDragonLevel()
    local data = self.data
    local attack = data.attackPlayerData
    return attack.fightWithHelpDefenceTroop and attack.fightWithHelpDefenceTroop.dragon.level or
        attack.fightWithDefenceTroop and attack.fightWithDefenceTroop.dragon.level or
        attack.dragon and attack.dragon.level
end
function Report:GetDefenceDragonLevel()
    local data = self.data
    local helpDefencePlayerData = data.helpDefencePlayerData
    local defencePlayerData = data.defencePlayerData
    local defenceMonsterData = data.defenceMonsterData

    return helpDefencePlayerData and helpDefencePlayerData.dragon.level or
        defencePlayerData and defencePlayerData.dragon.level or
        defenceMonsterData and defenceMonsterData.dragon.level
end
function Report:GetAttackTargetTerrain()
    local data = self.data
    return data.attackTarget.terrain
end
return Report
















































