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
Report.REPORT_TYPE = Enum("strikeCity","cityBeStriked","strikeVillage","villageBeStriked","attackCity","attackVillage","collectResource")
local STRIKECITY,CITYBESTRIKED,STRIKEVILLAGE,VILLAGEBESTRIKED,ATTACKCITY,ATTACKVILLAGE,COLLECTRESOURCE = 1,2,3,4,5,6,7
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
        return data.helpDefencePlayerData or data.defencePlayerData or data.defenceVillageData
    else
        return data.attackPlayerData
    end
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
function Report:GetMyDefenceFightPlayerData()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.attackPlayerData
    else
        return data.defencePlayerData or data.defenceVillageData
    end
end
function Report:GetEnemyDefenceFightPlayerData()
    local data = self:GetData()
    if self.player_id == data.attackPlayerData.id then
        return data.defencePlayerData or data.defenceVillageData
    else
        return data.attackPlayerData
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
    else
        return data.attackPlayerData.fightWithDefenceTroop and data.attackPlayerData.fightWithDefenceTroop.dragon
            or data.attackPlayerData and data.attackPlayerData.dragon
    end
end

function Report:GetMyRoundDatas()
    local data = self:GetData()
    local round_datas = {}
    if self.player_id == data.attackPlayerData.id then
        if data.fightWithHelpDefencePlayerReports then
            table.insert(round_datas, data.fightWithHelpDefencePlayerReports.attackPlayerSoldierRoundDatas)
        end
        if data.fightWithDefencePlayerReports then
            table.insert(round_datas, data.fightWithDefencePlayerReports.attackPlayerSoldierRoundDatas)
            if data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas then
                table.insert(round_datas, data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas)
            end
        end
        if data.fightWithDefenceVillageReports then
            table.insert(round_datas, data.fightWithDefenceVillageReports.attackPlayerSoldierRoundDatas)
        end
    else
        if data.fightWithHelpDefencePlayerReports then
            table.insert(round_datas, data.fightWithHelpDefencePlayerReports.defencePlayerSoldierRoundDatas)
        end
        if data.fightWithDefencePlayerReports then
            table.insert(round_datas, data.fightWithDefencePlayerReports.defencePlayerSoldierRoundDatas)
        end
    end
    return round_datas
end
function Report:GetEnemyRoundDatas()
    local data = self:GetData()
    local round_datas = {}
    -- LuaUtils:outputTable("data", data)
    if self.player_id == data.attackPlayerData.id then
        if data.fightWithHelpDefencePlayerReports then
            table.insert(round_datas, data.fightWithHelpDefencePlayerReports.defencePlayerSoldierRoundDatas)
        end
        if data.fightWithDefencePlayerReports then
            table.insert(round_datas, data.fightWithDefencePlayerReports.defencePlayerSoldierRoundDatas)
        end
    else
        if data.fightWithHelpDefencePlayerReports then
            table.insert(round_datas, data.fightWithHelpDefencePlayerReports.attackPlayerSoldierRoundDatas)
        end
        if data.fightWithDefencePlayerReports then
            table.insert(round_datas, data.fightWithDefencePlayerReports.attackPlayerSoldierRoundDatas)
            if data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas then
                table.insert(round_datas, data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas)
            end
        end
        if data.fightWithDefenceVillageReports then
            table.insert(round_datas, data.fightWithDefenceVillageReports.attackPlayerSoldierRoundDatas)
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
    elseif self.type == Report.REPORT_TYPE[COLLECTRESOURCE] then
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
        or self.type == Report.REPORT_TYPE[ATTACKVILLAGE] then
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
            return result and _("进攻村落成功") or _("进攻村落失败")
        elseif data.defencePlayerData and data.defencePlayerData.id == self.player_id then
            return result and _("防守村落成功") or _("防守村落失败")
        end
    elseif report_type=="collectResource" then
        return _("采集报告")
    end
end
function Report:IsFromMe()
    local data = self:GetData()
    local report_type = self.type
    if report_type == "strikeCity"
        or report_type=="strikeVillage"
        or report_type=="attackVillage" then
        return true
    elseif report_type=="villageBeStriked"
        or report_type=="cityBeStriked" then
        return false
    elseif report_type=="attackCity" then
        return data.attackTarget.id ~= self.player_id
    elseif report_type=="collectResource" then
        return "collectResource"
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
        or data.defenceVillageData and Localize.village_name[data.defenceVillageData.type].." Lv "..data.defenceVillageData.level
end
function Report:IsDragonFight()
    local data = self:GetFightReports()
    return data.attackPlayerDragonFightData
end
function Report:GetFightAttackDragonRoundData()
    local data = self:GetFightReports()
    return data.attackPlayerDragonFightData or {}
end
function Report:GetFightDefenceDragonRoundData()
    local data = self:GetFightReports()
    return data.defencePlayerDragonFightData or {}
end
function Report:GetFightAttackSoldierRoundData()
    local data = self:GetFightReports()
    return data.attackPlayerSoldierRoundDatas or {}
end
function Report:GetFightDefenceSoldierRoundData()
    local data = self:GetFightReports()
    return data.defencePlayerSoldierRoundDatas or {}
end
function Report:IsFightWall()
    local data = self:GetFightReports()
    return  data.attackPlayerWallRoundDatas and #data.attackPlayerWallRoundDatas > 0
end
function Report:GetFightAttackWallRoundData()
    local data = self:GetFightReports()
    return data.attackPlayerWallRoundDatas or {}
end
function Report:GetFightDefenceWallRoundData()
    local data = self:GetFightReports()
    return data.defencePlayerWallRoundDatas or {}
end
function Report:GetOrderedAttackSoldiers()
    local attackPlayerData = self:GetData().attackPlayerData
    local troop = attackPlayerData.fightWithHelpDefenceTroop or attackPlayerData.fightWithDefenceTroop or attackPlayerData.fightWithDefenceWall
    local soldiers = troop and  troop.soldiers or attackPlayerData.soldiers or {}
    return soldiers
end
function Report:GetOrderedDefenceSoldiers()
    local data = self:GetData()
    local defenceData = data.helpDefencePlayerData or data.defencePlayerData
    local soldiers = defenceData and defenceData.soldiers or {}
    return soldiers
end
function Report:GetFightReports()
    local data = self:GetData()
    return data.fightWithHelpDefencePlayerReports or data.fightWithDefencePlayerReports
        or {}
end
function Report:GetReportResult()
    local data = self.data
    if data.attackPlayerData.id == self.player_id then
        if data.fightWithHelpDefencePlayerReports then
            local my_round = data.fightWithHelpDefencePlayerReports.attackPlayerSoldierRoundDatas
            local defence_round = data.fightWithHelpDefencePlayerReports.defencePlayerSoldierRoundDatas
            -- 判定是否双方所有士兵都参加了战斗
            local my_soldiers = self:GetOrderedAttackSoldiers()
            local defence_soldiers = self:GetOrderedDefenceSoldiers()
            for i,s in ipairs(my_soldiers) do
                local isFight = false
                for i,r in ipairs(my_round) do
                    if s.name == r.soldierName then
                        isFight = true
                    end
                end
                if not isFight then
                    return true
                end
            end
            for i,s in ipairs(defence_soldiers) do
                local isFight = false
                for i,r in ipairs(defence_round) do
                    if s.name == r.soldierName then
                        isFight = true
                    end
                end
                if not isFight then
                    return false
                end
            end

            return my_round[#my_round].isWin
        elseif data.fightWithDefencePlayerReports then
            -- 打到城墙，直接算赢
            local wall_round = data.fightWithDefencePlayerReports.attackPlayerWallRoundDatas
            if wall_round then
                return true
            end
            local my_round = data.fightWithDefencePlayerReports.attackPlayerSoldierRoundDatas
            local defence_round = data.fightWithDefencePlayerReports.defencePlayerSoldierRoundDatas
            -- 判定是否双方所有士兵都参加了战斗
            local my_soldiers = self:GetOrderedAttackSoldiers()
            local defence_soldiers = self:GetOrderedDefenceSoldiers()
            for i,s in ipairs(my_soldiers) do
                local isFight = false
                for i,r in ipairs(my_round) do
                    if s.name == r.soldierName then
                        isFight = true
                    end
                end
                if not isFight then
                    return true
                end
            end
            for i,s in ipairs(defence_soldiers) do
                local isFight = false
                for i,r in ipairs(defence_round) do
                    if s.name == r.soldierName then
                        isFight = true
                    end
                end
                if not isFight then
                    return false
                end
            end
            return my_round[#my_round].isWin
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
        local my_round = data.fightWithDefencePlayerReports.defencePlayerSoldierRoundDatas
        local attact_round = data.fightWithDefencePlayerReports.attackPlayerSoldierRoundDatas
        -- 判定是否双方所有士兵都参加了战斗
        local attack_soldiers = self:GetOrderedAttackSoldiers()
        local my_soldiers = self:GetOrderedDefenceSoldiers()
        for i,s in ipairs(my_soldiers) do
            local isFight = false
            for i,r in ipairs(my_round) do
                if s.name == r.soldierName then
                    isFight = true
                end
            end
            if not isFight then
                return true
            end
        end
        for i,s in ipairs(attack_soldiers) do
            local isFight = false
            for i,r in ipairs(attact_round) do
                if s.name == r.soldierName then
                    isFight = true
                end
            end
            if not isFight then
                return false
            end
        end
        return my_round[#my_round].isWin
    elseif data.helpDefencePlayerData and
        data.helpDefencePlayerData.id == self.player_id then
        local my_round = data.fightWithHelpDefencePlayerReports.defencePlayerSoldierRoundDatas
        local attact_round = data.fightWithHelpDefencePlayerReports.attackPlayerSoldierRoundDatas
        -- 判定是否双方所有士兵都参加了战斗
        local attack_soldiers = self:GetOrderedAttackSoldiers()
        local my_soldiers = self:GetOrderedDefenceSoldiers()
        for i,s in ipairs(my_soldiers) do
            local isFight = false
            for i,r in ipairs(my_round) do
                if s.name == r.soldierName then
                    isFight = true
                end
            end
            if not isFight then
                return true
            end
        end
        for i,s in ipairs(attack_soldiers) do
            local isFight = false
            for i,r in ipairs(attact_round) do
                if s.name == r.soldierName then
                    isFight = true
                end
            end
            if not isFight then
                return false
            end
        end
        return my_round[#my_round].isWin
    end
end
function Report:GetAttackDragonLevel()
    local data = self.data
    local attack = data.attackPlayerData
    return attack.fightWithHelpDefenceTroop and attack.fightWithHelpDefenceTroop.dragon.level or
        attack.fightWithDefenceTroop and attack.fightWithDefenceTroop.dragon.level
end
function Report:GetDefenceDragonLevel()
    local data = self.data
    local helpDefencePlayerData = data.helpDefencePlayerData
    local defencePlayerData = data.defencePlayerData

    return helpDefencePlayerData and helpDefencePlayerData.dragon.level or
        defencePlayerData and defencePlayerData.dragon.level
end
function Report:GetAttackTargetTerrain()
    local data = self.data
    return data.attackTarget.terrain
end
return Report




































