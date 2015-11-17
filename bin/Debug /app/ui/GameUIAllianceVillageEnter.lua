--
-- Author: Danny He
-- Date: 2014-12-29 16:35:40
--
local GameUIAllianceVillageEnter = UIKit:createUIClass("GameUIAllianceVillageEnter","GameUIAllianceEnterBase")
local Localize = import("..utils.Localize")
local VillageEvent = import("..entity.VillageEvent")
local GameUIStrikePlayer = import(".GameUIStrikePlayer")
local SpriteConfig = import("..sprites.SpriteConfig")
local UILib = import(".UILib")
local BelvedereEntity = import("..entity.BelvedereEntity")

function GameUIAllianceVillageEnter:ctor(building,alliance)
    GameUIAllianceVillageEnter.super.ctor(self,building,alliance)
    -- self.enemy_alliance = enemy_alliance
    -- self.village_info = alliance:FindAllianceVillagesInfoByObject(building)
    -- self.map_id = building.id
end


function GameUIAllianceVillageEnter:IsRuins()
    return false
end

function GameUIAllianceVillageEnter:GetVillageInfo()
    return self:GetFocusAlliance():GetAllianceVillageInfosById(self:GetBuilding().id)
end

function GameUIAllianceVillageEnter:GetProcessIconConfig()
    local config  = {
        woodVillage = {"res_wood_82x73.png",41/82},
        stoneVillage= {"res_stone_88x82.png",41/88},
        ironVillage = {"res_iron_91x63.png",41/91},
        foodVillage = {"res_food_91x74.png",41/91},
        coinVillage = {"res_coin_81x68.png",41/81},
    }
    return config
end

function GameUIAllianceVillageEnter:GetProcessIcon()
    local config = self:GetProcessIconConfig()
    return unpack(config[self:GetBuilding().name])
end

function GameUIAllianceVillageEnter:HasEnemyAlliance()
    return self:GetEnemyAlliance() ~= nil
end

function GameUIAllianceVillageEnter:GetEnemyAlliance()
    return self.enemy_alliance
end

function GameUIAllianceVillageEnter:GetBuildingInfoOriginalY()
    return self.process_bar_bg:getPositionY() - self.process_bar_bg:getContentSize().height - 40
end
function GameUIAllianceVillageEnter:GetUIHeight()
    return 290
end

function GameUIAllianceVillageEnter:GetProcessLabelText()
    return ""
end

function GameUIAllianceVillageEnter:FixedUI()
    self:GetDescLabel():hide()
    self:GetLevelBg():show()
    self.process_bar_bg:show()
    self:GetHonourIcon():hide()
    self:GetHonourLabel():hide()
end

function GameUIAllianceVillageEnter:GetUITitle()
    return Localize.village_name[self:GetBuilding().name]
end

function GameUIAllianceVillageEnter:GetBuildImageSprite()
    return nil
end

function GameUIAllianceVillageEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 110/math.max(size.width,size.height),97,self:GetUIHeight() - 90
end

function GameUIAllianceVillageEnter:GetBuildingImage()
    local village_info = self:GetVillageInfo()
    local build_png = SpriteConfig[village_info.name]:GetConfigByLevel(village_info.level).png
    return build_png
end

function GameUIAllianceVillageEnter:GetBuildingType()
    return 'village'
end

function GameUIAllianceVillageEnter:GetBuildingDesc()
    return ""
end
function GameUIAllianceVillageEnter:InitBuildingInfo()
    GameUIAllianceVillageEnter.super.InitBuildingInfo(self)
end
function GameUIAllianceVillageEnter:GetBuildingInfo()
    local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local labels = {}
    local village_id = self:GetVillageInfo().id
    local villageEvent = Alliance_Manager:GetVillageEventsByMapId(self:GetMyAlliance(), village_id)
    dump(villageEvent,"villageEvent")
    if villageEvent then --我方占领
        local startTime = villageEvent.startTime/1000.0
        local finishTime = villageEvent.finishTime/1000.0
        local collectTime = app.timer:GetServerTime() - startTime
        local collectSpeed = villageEvent.villageData.collectTotal/(finishTime - startTime)
        local collectCount = math.floor(collectSpeed * collectTime)
        local occupy_label = {
            {_("占领者"),0x615b44},
            {villageEvent.playerData.name,0x403c2f}
        }
        local current_collect_label =  {
            {_("当前采集"),0x615b44},
            {collectCount .. "(" .. math.floor(collectCount/villageEvent.villageData.collectTotal * 100)  .. "%)",0x403c2f,900},
        }
        local end_time_label = {
            {_("完成时间"),0x615b44},
            {
                villageEvent.finishTime/1000.0 <= app.timer:GetServerTime() and _("已完成") or GameUtils:formatTimeStyle1(math.ceil(finishTime - app.timer:GetServerTime())),
                0x403c2f,
                1000
            },
        }
        labels = {location,occupy_label,current_collect_label,end_time_label}
        local str = string.formatnumberthousands(self:GetVillageInfo().resource - collectCount) .. "/" .. string.formatnumberthousands(VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production)
        local percent = (self:GetVillageInfo().resource - collectCount)/VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production
        self:GetProgressTimer():setPercentage(percent*100)
        self:GetProcessLabel():setString(str)
        scheduleAt(self, function()
            local villageEvent = Alliance_Manager:GetVillageEventsByMapId(self:GetMyAlliance(), village_id)
            if not villageEvent then
                self:LeftButtonClicked()
                return
            end
            local collectTime = app.timer:GetServerTime() - startTime
            local collectCount = math.floor(collectSpeed * collectTime)

            local str = string.formatnumberthousands(self:GetVillageInfo().resource - collectCount) .. "/" .. string.formatnumberthousands(VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production)
            local percent = (self:GetVillageInfo().resource - collectCount)/VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production
            self:GetProgressTimer():setPercentage(percent*100)
            self:GetProcessLabel():setString(str)
            local label = self:GetInfoLabelByTag(900)
            if label then
                label:setString(string.formatnumberthousands(collectCount) .. "(" .. math.floor(collectCount/villageEvent.villageData.collectTotal * 100)  .. "%)")
            end
            local label = self:GetInfoLabelByTag(1000)
            if label then
                label:setString(GameUtils:formatTimeStyle1(math.ceil(finishTime - app.timer:GetServerTime())))
            end
        end)
    else --没人占领
        local no_one_label = {
            {_("占领者"),0x615b44},
            {_("无"),0x403c2f}
        }
    labels = {location,no_one_label}
    local str = string.formatnumberthousands(self:GetVillageInfo().resource) .. "/" .. string.formatnumberthousands(VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production)
    local percent = self:GetVillageInfo().resource/VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production
    self:GetProgressTimer():setPercentage(percent*100)
    self:GetProcessLabel():setString(str)
    end
    return labels
end

function GameUIAllianceVillageEnter:OnVillageEventTimer(village_event,left_resource)
    if village_event:VillageData().id == self:GetVillageInfo().id then
        local str = string.formatnumberthousands(left_resource) .. "/" .. string.formatnumberthousands(VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production)
        local percent = left_resource/VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production
        self:GetProgressTimer():setPercentage(percent*100)
        self:GetProcessLabel():setString(str)
        local label = self:GetInfoLabelByTag(900)
        if label then
            label:setString(string.formatnumberthousands(village_event:CollectCount()) .. "(" .. village_event:CollectPercent() .. "%)")
        end
        local label = self:GetInfoLabelByTag(1000)
        if label then
            label:setString(GameUtils:formatTimeStyle1(village_event:GetTime()))
        end
    end
end

-- function GameUIAllianceVillageEnter:OnBuildingDeltaUpdate(alliance_map,mapObjects)
--     self:OnBuildingChange(alliance_map)
-- end

-- function GameUIAllianceVillageEnter:OnBuildingFullUpdate(alliance_map)
--     self:OnBuildingChange(alliance_map)
-- end

-- function GameUIAllianceVillageEnter:OnBuildingChange(alliance_map)
--     local has = false
--     self:GetAlliance():IteratorVillages(function(__,v)
--         if v:Id()== self.map_id then
--             has = true
--         end
--     end)
--     if has then
--         self:RefreshUI()
--     else
--         self:LeftButtonClicked()
--     end
-- end

function GameUIAllianceVillageEnter:OnVillageEventsDataChanged(changed_map)
    local hasHandler = false
    if changed_map.removed then
        for _,v in ipairs(changed_map.removed) do
            if v:VillageData().id == self:GetVillageInfo().id then
                self:RefreshUI()
                hasHandler = true
            end
        end
    end
    if changed_map.added and not hasHandler then
        for _,v in ipairs(changed_map.added) do
            if v:VillageData().id == self:GetVillageInfo().id then
                self:RefreshUI()
                hasHandler = true
            end
        end
    end
end

function GameUIAllianceVillageEnter:GetLevelLabelText()
    return _("等级") .. self:GetVillageInfo().level
end
--关闭了进攻和突袭的条件判断
function GameUIAllianceVillageEnter:CheckCanAttackVillage()
    return true
end

function GameUIAllianceVillageEnter:GetEnterButtons()
    local buttons = {}
    local village_id = self:GetVillageInfo().id
    local villageEvent = Alliance_Manager:GetVillageEventsByMapId(self:GetMyAlliance(), village_id)
    local alliance_id = self:GetFocusAlliance()._id
    local checkMeIsProtectedWarinng = self:CheckMeIsProtectedWarinng()
    local focus_alliance = self:GetFocusAlliance()
    if villageEvent and villageEvent.fromAlliance.id == self:GetMyAlliance()._id then --我方占领
        if villageEvent.playerData.id == User:Id() then --自己占领
            local che_button = self:BuildOneButton("capture_38x56.png",_("撤军")):onButtonClicked(function()
                NetManager:getRetreatFromVillagePromise(villageEvent.id)
                self:LeftButtonClicked()
            end)
            local info_button = self:BuildOneButton("icon_info_56x56.png",_("部队")):onButtonClicked(function()
                self:FindTroopShowInfoFromAllianceBelvedere()
                self:LeftButtonClicked()
            end)
            buttons =  {che_button,info_button}
        else --盟友占领
            local position = self:GetLogicPosition()
            local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
                local final_func = function ()
                    local attack_func = function ()
                        UIKit:showMessageDialog(_("提示"), _("当前资源点已被盟友占领，你可能无法进行采集，仍要派兵吗？"), function ()
                            UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                                NetManager:getAttackVillagePromise(dragonType,soldiers,alliance_id,village_id):done(function()
                                    app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                    gameuialliancesendtroops:LeftButtonClicked()
                                end)
                            end,{targetAlliance = focus_alliance,toLocation = position,returnCloseAction = true}):AddToCurrentScene(true)
                        end)
                    end, function ()
                    end
                    UIKit:showSendTroopMessageDialog(attack_func,"dragonMaterials",_("龙"))
                end
                if checkMeIsProtectedWarinng then
                    UIKit:showMessageDialog(_("提示"),_("进攻村落将失去保护状态，确定继续派兵?"),final_func)
                else
                    final_func()
                end
            end)
            buttons = {attack_button}
        end
    else --我方未占领
        if villageEvent then -- 敌方占领
            local attack_button = self:BuildOneButton("capture_38x56.png", _("占领")):onButtonClicked(function()
                local toLocation = self:GetLogicPosition()

                local final_func = function ()
                    local attack_func = function ()
                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                            NetManager:getAttackVillagePromise(dragonType,soldiers,alliance_id,village_id):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                gameuialliancesendtroops:LeftButtonClicked()
                            end)
                        end,{targetAlliance = focus_alliance,toLocation = toLocation,returnCloseAction = true}):AddToCurrentScene(true)
                    end
                    UIKit:showSendTroopMessageDialog(attack_func,"dragonMaterials",_("龙"))
                end

                if checkMeIsProtectedWarinng then
                    UIKit:showMessageDialog(_("提示"),_("进攻村落将失去保护状态，确定继续派兵?"),final_func)
                else
                    final_func()
                end
            end)
            local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
                local toLocation = self:GetLogicPosition()
                if checkMeIsProtectedWarinng then
                    UIKit:showMessageDialog(_("提示"),_("突袭村落将失去保护状态，确定继续派兵?"),function ()
                        UIKit:newGameUI("GameUIStrikePlayer",GameUIStrikePlayer.STRIKE_TYPE.VILLAGE,{alliance = focus_alliance,toLocation = toLocation,defenceAllianceId = alliance_id,defenceVillageId = village_id}):AddToCurrentScene(true)
                    end)
                else
                    UIKit:newGameUI("GameUIStrikePlayer",GameUIStrikePlayer.STRIKE_TYPE.VILLAGE,{alliance = focus_alliance,toLocation = toLocation,defenceAllianceId = alliance_id,defenceVillageId = village_id}):AddToCurrentScene(true)
                end
            end)
            buttons = {attack_button,strike_button}
        else -- 无人占领
            local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
                local toLocation = self:GetLogicPosition()

                local final_func = function ()
                    local attack_func = function ()
                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers,total_march_time,gameuialliancesendtroops)
                            NetManager:getAttackVillagePromise(dragonType,soldiers,alliance_id,village_id):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                                gameuialliancesendtroops:LeftButtonClicked()
                            end)
                        end,{targetAlliance = focus_alliance,toLocation = toLocation,returnCloseAction = true}):AddToCurrentScene(true)
                    end
                    UIKit:showSendTroopMessageDialog(attack_func, "dragonMaterials",_("龙"))
                end


                if checkMeIsProtectedWarinng then
                    UIKit:showMessageDialog(_("提示"),_("进攻村落将失去保护状态，确定继续派兵?"),final_func)
                else
                    final_func()
                end
            end)
            buttons = {attack_button}
        end
    end
    return buttons
end

function GameUIAllianceVillageEnter:OnAllianceBasicChanged( alliance,deltaData )
-- local ok, value = deltaData("basicInfo.status")
-- if ok and not self:IsMyAlliance() then
--     self:GetEnterButtonByIndex(1):setButtonEnabled(value == "fight")
--     if self:GetEnterButtonByIndex(2) then
--         self:GetEnterButtonByIndex(2):setButtonEnabled(value == "fight")
--     end
-- end
end

function GameUIAllianceVillageEnter:FindTroopShowInfoFromAllianceBelvedere()
    local village_id = self:GetVillageInfo().id
    local villageEvent = self:GetMyAlliance():FindVillageEventByVillageId(village_id)
    if villageEvent then
        if villageEvent.playerData.id == User:Id() then
            UIKit:newGameUI("GameUIWatchTowerMyTroopsDetail", villageEvent, "villageEvents"):AddToCurrentScene(true)
        end
    end
end

function GameUIAllianceVillageEnter:OnMoveOutStage()
    -- self:GetMyAlliance():RemoveListenerOnType(self,self:GetMyAlliance().LISTEN_TYPE.BASIC)
    -- self:GetMyAlliance():RemoveListenerOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventTimer)
    -- self:GetMyAlliance():RemoveListenerOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    -- local alliance_map = self:GetMyAlliance():GetAllianceMap()
    -- alliance_map:RemoveListenerOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
    if self:HasEnemyAlliance() then
    -- local alliance_map = self:GetEnemyAlliance():GetAllianceMap()
    -- alliance_map:RemoveListenerOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
    -- self:GetEnemyAlliance():RemoveListenerOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventTimer)
    -- self:GetEnemyAlliance():RemoveListenerOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    end
    GameUIAllianceVillageEnter.super.OnMoveOutStage(self)
end
return GameUIAllianceVillageEnter



















