local Alliance = import(".Alliance")
local AllianceManager = class("AllianceManager")

function AllianceManager:ctor()
    self.my_alliance = Alliance.new()
    self.my_alliance:SetIsMyAlliance(true)
    self.enemy_alliance = Alliance.new()
    self.enemy_alliance:SetIsMyAlliance(false)
    -- 己方的瞭望塔监听敌方联盟的瞭望塔事件,瞭望塔coming不需要知道敌方对自己联盟的村落事件和行军返回事件 
    local enemy_belvedere = self.enemy_alliance:GetAllianceBelvedere()
    local my_belvedere = self.my_alliance:GetAllianceBelvedere()
    enemy_belvedere:AddListenOnType(my_belvedere, enemy_belvedere.LISTEN_TYPE.OnAttackMarchEventTimerChanged)
    enemy_belvedere:AddListenOnType(my_belvedere, enemy_belvedere.LISTEN_TYPE.OnStrikeMarchEventDataChanged)
    enemy_belvedere:AddListenOnType(my_belvedere, enemy_belvedere.LISTEN_TYPE.OnAttackMarchEventDataChanged)
end

function AllianceManager:GetMyAlliance()
    return self.my_alliance
end

function AllianceManager:GetEnemyAlliance()
    return self.enemy_alliance
end

function AllianceManager:HaveEnemyAlliance()
    return not self:GetEnemyAlliance():IsDefault()
end

function AllianceManager:OnUserDataChanged(user_data,time,deltaData)
    local allianceId = user_data.allianceId
    local my_alliance = self:GetMyAlliance()
    if (allianceId == json.null or not allianceId) and not my_alliance:IsDefault() then
        my_alliance:Reset()
        DataManager:setUserAllianceData(json.null)
        DataManager:setEnemyAllianceData(json.null) -- 清除敌方联盟数据
    else
        my_alliance:SetId(allianceId)
    end
end

function AllianceManager:OnAllianceDataChanged(alliance_data,refresh_time,deltaData)
    local my_alliance_status = self:GetMyAlliance():Status() 
    self:GetMyAlliance():OnAllianceDataChanged(alliance_data,refresh_time,deltaData)
    self:RefreshAllianceSceneIf(my_alliance_status)
end

function AllianceManager:OnEnemyAllianceDataChanged(enemyAllianceData,refresh_time,deltaData)
    local alliance = self:GetEnemyAlliance()
    if enemyAllianceData == json.null or not enemyAllianceData then
        alliance:Reset()
    else
        if enemyAllianceData._id then
            alliance:SetId(enemyAllianceData._id)
        end
        if enemyAllianceData.basicInfo then
            alliance:SetName(enemyAllianceData.basicInfo.name)
            alliance:SetTag(enemyAllianceData.basicInfo.tag)
        end
        alliance:OnAllianceDataChanged(enemyAllianceData,refresh_time,deltaData)
    end
end

function AllianceManager:OnTimer(current_time)
    self:GetMyAlliance():OnTimer(current_time)
    if self:HaveEnemyAlliance() then
        self:GetEnemyAlliance():OnTimer(current_time)
    end
end
-- json decode to a alliance
function AllianceManager:DecodeAllianceFromJson( json_data )
    local alliance = Alliance.new()
    alliance:SetId(json_data._id)
    alliance:OnAllianceDataChanged(json_data)
    return alliance
end
--判断是否进入对战地图
function AllianceManager:RefreshAllianceSceneIf(old_alliance_status)
    local my_alliance = self:GetMyAlliance()
    local my_alliance_status = my_alliance:Status()
    if old_alliance_status == my_alliance_status then return end
    local scene_name = display.getRunningScene().__cname
    if (my_alliance_status == 'protect' or my_alliance_status == 'peace') then
        if self:HaveEnemyAlliance() then
            self:GetEnemyAlliance():Reset()
        end
        if scene_name == 'AllianceBattleScene' then
            app:EnterMyAllianceSceneWithTips(_("联盟对战已结束，您将进入自己联盟领地。"))
        end
    end
    if (my_alliance_status == 'prepare' or my_alliance_status == 'fight') then
        if scene_name == 'AllianceScene' then
            app:EnterMyAllianceSceneWithTips(_("联盟对战已开始，您将进入自己联盟对战地图。"))
        elseif scene_name == 'MyCityScene' then
            UIKit:showMessageDialogCanCanleNotAutoClose(
                nil,
                _("联盟对战已开始，您将进入自己联盟对战地图。"),
                function()
                    app:EnterMyAllianceScene()
                end,
                function()
                end
            )
        end
    end
    
end

return AllianceManager

