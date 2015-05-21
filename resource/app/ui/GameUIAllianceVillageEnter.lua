--
-- Author: Danny He
-- Date: 2014-12-29 16:35:40
--
local GameUIAllianceVillageEnter = UIKit:createUIClass("GameUIAllianceVillageEnter","GameUIAllianceEnterBase")
local Localize = import("..utils.Localize")
local VillageEvent = import("..entity.VillageEvent")
local GameUIStrikePlayer = import(".GameUIStrikePlayer")
local WidgetAllianceEnterButtonProgress = import("..widget.WidgetAllianceEnterButtonProgress")
local SpriteConfig = import("..sprites.SpriteConfig")
local UILib = import(".UILib")
local BelvedereEntity = import("..entity.BelvedereEntity")

function GameUIAllianceVillageEnter:ctor(building,isMyAlliance,my_alliance,enemy_alliance)
    GameUIAllianceVillageEnter.super.ctor(self,building,isMyAlliance,my_alliance)
    self.enemy_alliance = enemy_alliance
    self.village_info = building:GetAllianceVillageInfo()
    self.map_id = building:Id()
end


function GameUIAllianceVillageEnter:IsRuins()
    return false
end

function GameUIAllianceVillageEnter:GetVillageInfo()
    return self.village_info
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
    return unpack(config[self:GetBuilding():GetName()])
end

function GameUIAllianceVillageEnter:HasEnemyAlliance()
    return self:GetEnemyAlliance() ~= nil
end

function GameUIAllianceVillageEnter:GetEnemyAlliance()
    return self.enemy_alliance
end

function GameUIAllianceVillageEnter:GetBuildingInfoOriginalY()
    if not self:IsRuins() then
        return self.process_bar_bg:getPositionY() - self.process_bar_bg:getContentSize().height-40
    else
        return self.process_bar_bg:getPositionY() - self.process_bar_bg:getContentSize().height
    end
end
function GameUIAllianceVillageEnter:GetUIHeight()
    return 311
end

function GameUIAllianceVillageEnter:GetProcessLabelText()
    return ""
end

function GameUIAllianceVillageEnter:FixedUI()
    if self:IsRuins() then
        self:GetDescLabel():hide()
        self:GetLevelBg():hide()
        self.process_bar_bg:hide()
    else
        self:GetDescLabel():hide()
        self:GetLevelBg():show()
        self.process_bar_bg:show()
    end
    self:GetHonourIcon():hide()
    self:GetHonourLabel():hide()
end

function GameUIAllianceVillageEnter:GetUITitle()
    return Localize.village_name[self:GetBuilding():GetName()]
end

function GameUIAllianceVillageEnter:GetBuildImageSprite()
    return nil
end

function GameUIAllianceVillageEnter:GetBuildImageInfomation(sprite)
    local size = sprite:getContentSize()
    return 110/math.max(size.width,size.height),97,self:GetUIHeight() - 90
end

function GameUIAllianceVillageEnter:GetBuildingImage()
    if not self:IsRuins() then
        local village_info = self:GetVillageInfo()
        local build_png = SpriteConfig[village_info.name]:GetConfigByLevel(village_info.level).png
        return build_png
    else
        local terrain = self:IsMyAlliance() and self:GetMyAlliance():Terrain() or self:GetEnemyAlliance():Terrain()
        local village_name = self:GetBuilding():GetName()

        if village_name == 'woodVillage' then
            local decorate_tree = UILib.decorator_image[terrain].decorate_tree_1
            return decorate_tree
        elseif village_name == 'ironVillage' then
            return "iron_ruins_276x200.png"
        elseif village_name == 'stoneVillage' then
            local stone_mountain = UILib.decorator_image[terrain].stone_mountain
            return stone_mountain
        elseif village_name == 'foodVillage' then
            local farmland = UILib.decorator_image[terrain].farmland
            return farmland
        end
    end
end

function GameUIAllianceVillageEnter:GetBuildingType()
    return 'village'
end

function GameUIAllianceVillageEnter:GetBuildingDesc()
    if self:IsRuins() then
        return _("废弃的村落")
    end
    return ""
end

function GameUIAllianceVillageEnter:GetBuildingInfo()
    if self:IsRuins() then
        return {{
            {_("坐标"),0x615b44},
            {self:GetLocation(),0x403c2f},
        }}
    end
    self:GetMyAlliance():RemoveListenerOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    self:GetMyAlliance():AddListenOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    local alliance_map = self:GetMyAlliance():GetAllianceMap()
    alliance_map:RemoveListenerOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
    alliance_map:AddListenOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
    if self:HasEnemyAlliance() then
        local alliance_map = self:GetEnemyAlliance():GetAllianceMap()
        alliance_map:RemoveListenerOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
        alliance_map:AddListenOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
        self:GetEnemyAlliance():RemoveListenerOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
        self:GetEnemyAlliance():AddListenOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    end
    local location = {
        {_("坐标"),0x615b44},
        {self:GetLocation(),0x403c2f},
    }
    local labels = {}
    local village_id = self:GetVillageInfo().id
    local villageEvent = self:GetMyAlliance():FindVillageEventByVillageId(village_id)
    if not villageEvent  then --我方未占领
        if self:HasEnemyAlliance() then
            villageEvent = self:GetEnemyAlliance():FindVillageEventByVillageId(village_id)
            if villageEvent then  --敌方联盟人占领
                local occupy_label = {
                    {_("占领者"),0x615b44},
                    {villageEvent:PlayerData().name,0x403c2f}
                }
            local current_collect_label =  {
                {_("当前采集"),0x615b44},
                {villageEvent:CollectCount() .. "(" .. villageEvent:CollectPercent()  .. "%)",0x403c2f,900},
            }
            local end_time_label = {
                {_("完成时间"),0x615b44},
                {
                    villageEvent:GetTime() == 0 and _("已完成") or GameUtils:formatTimeStyle1(villageEvent:GetTime()),
                    0x403c2f,
                    1000
                },
            }
            labels = {location,occupy_label,current_collect_label,end_time_label}
            local str = string.formatnumberthousands(self:GetVillageInfo().resource - villageEvent:CollectCount()) .. "/" .. string.formatnumberthousands(VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production)
            local percent = (self:GetVillageInfo().resource - villageEvent:CollectCount())/VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production
            self:GetProgressTimer():setPercentage(percent*100)
            self:GetProcessLabel():setString(str)
            self:GetEnemyAlliance():AddListenOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventTimer)
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
    else --我方占领
        local occupy_label = {
            {_("占领者"),0x615b44},
            {villageEvent:PlayerData().name,0x403c2f}
        }
    local current_collect_label =  {
        {_("当前采集"),0x615b44},
        {villageEvent:CollectCount() .. "(" .. villageEvent:CollectPercent()  .. "%)",0x403c2f,900},
    }
    local end_time_label = {
        {_("完成时间"),0x615b44},
        {
            villageEvent:GetTime() == 0 and _("已完成") or GameUtils:formatTimeStyle1(villageEvent:GetTime()),
            0x403c2f,
            1000
        },
    }
    labels = {location,occupy_label,current_collect_label,end_time_label}
    local str = string.formatnumberthousands(self:GetVillageInfo().resource - villageEvent:CollectCount()) .. "/" .. string.formatnumberthousands(VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production)
    local percent = (self:GetVillageInfo().resource - villageEvent:CollectCount())/VillageEvent.GetVillageConfig(self:GetVillageInfo().name,self:GetVillageInfo().level).production
    self:GetProgressTimer():setPercentage(percent*100)
    self:GetProcessLabel():setString(str)
    self:GetMyAlliance():AddListenOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventTimer)
    end
    return labels
end

function GameUIAllianceVillageEnter:OnVillageEventTimer(village_event,left_resource)
    if self:IsRuins() then return end
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

function GameUIAllianceVillageEnter:OnBuildingDeltaUpdate(alliance_map,mapObjects)
    self:OnBuildingChange(alliance_map)
end

function GameUIAllianceVillageEnter:OnBuildingFullUpdate(alliance_map)
    self:OnBuildingChange(alliance_map)
end

function GameUIAllianceVillageEnter:OnBuildingChange(alliance_map)
    local has = false
    alliance_map:IteratorVillages(function(__,v)
        if v:Id()== self.map_id then
            has = true
        end
    end)
    if has then
        self:RefreshUI()
    else
        self:LeftButtonClicked()
    end
end

function GameUIAllianceVillageEnter:OnVillageEventsDataChanged(changed_map)
    if self:IsRuins() then return end
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
    if self:IsRuins() then return "" end
    return _("等级") .. self:GetVillageInfo().level
end
--关闭了进攻和突袭的条件判断
function GameUIAllianceVillageEnter:CheckCanAttackVillage()
    return true
end

function GameUIAllianceVillageEnter:GetEnterButtons()
    if self:IsRuins() then return {} end
    local buttons = {}
    local village_id = self:GetVillageInfo().id
    local villageEvent = self:GetMyAlliance():FindVillageEventByVillageId(village_id)
    if not villageEvent  then --我方未占领
        if self:HasEnemyAlliance() then
            villageEvent = self:GetEnemyAlliance():FindVillageEventByVillageId(village_id)
            if villageEvent then  --敌方联盟人占领
                local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
                    if self:CheckCanAttackVillage() then
                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                            NetManager:getAttackVillagePromise(dragonType,soldiers,villageEvent:VillageData().alliance.id,village_id):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                            end)
                        end,{targetIsMyAlliance = self:IsMyAlliance(),toLocation = self:GetLogicPosition()}):AddToCurrentScene(true)
                    end
                    self:LeftButtonClicked()
                end)
            local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
                if self:CheckCanAttackVillage() then
                    UIKit:newGameUI("GameUIStrikePlayer",{defenceAllianceId = villageEvent:VillageData().alliance.id,defenceVillageId = village_id},GameUIStrikePlayer.STRIKE_TYPE.VILLAGE):AddToCurrentScene(true)
                end
                self:LeftButtonClicked()
            end)
            buttons = {attack_button,strike_button}
            else --没人占领
                local alliance_id = self:IsMyAlliance() and self:GetMyAlliance():Id() or self:GetEnemyAlliance():Id()
                local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
                    if self:CheckCanAttackVillage() then
                        UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                            NetManager:getAttackVillagePromise(dragonType,soldiers,alliance_id,village_id):done(function()
                                app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                            end)
                        end,{targetIsMyAlliance = self:IsMyAlliance(),toLocation = self:GetLogicPosition()}):AddToCurrentScene(true)
                    end
                    self:LeftButtonClicked()
                end)
                local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
                    if self:CheckCanAttackVillage() then
                        UIKit:newGameUI("GameUIStrikePlayer",{defenceAllianceId = alliance_id,defenceVillageId = village_id},GameUIStrikePlayer.STRIKE_TYPE.VILLAGE):AddToCurrentScene(true)
                    end
                    self:LeftButtonClicked()
                end)
                if not self:IsMyAlliance() and self:GetMyAlliance():Status() == "prepare" then
                    local progress_1 = WidgetAllianceEnterButtonProgress.new()
                        :pos(-68, -54)
                        :addTo(attack_button)
                    local progress_2 = WidgetAllianceEnterButtonProgress.new()
                        :pos(-68, -54)
                        :addTo(strike_button)
                end
                buttons = {attack_button,strike_button}
            end
    else --没人占领
        local alliance_id = self:IsMyAlliance() and self:GetMyAlliance():Id() or self:GetEnemyAlliance():Id()
        local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
            if self:CheckCanAttackVillage() then
                UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                    NetManager:getAttackVillagePromise(dragonType,soldiers,alliance_id,village_id):done(function()
                        app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                    end)
                end,{targetIsMyAlliance = self:IsMyAlliance(),toLocation = self:GetLogicPosition()}):AddToCurrentScene(true)
            end
            self:LeftButtonClicked()
        end)
        local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
            if self:CheckCanAttackVillage() then
                UIKit:newGameUI("GameUIStrikePlayer",{defenceAllianceId = alliance_id,defenceVillageId = village_id},GameUIStrikePlayer.STRIKE_TYPE.VILLAGE):AddToCurrentScene(true)
            end
            self:LeftButtonClicked()
        end)
        if not self:IsMyAlliance() and self:GetMyAlliance():Status() == "prepare" then
            local progress_1 = WidgetAllianceEnterButtonProgress.new()
                :pos(-68, -54)
                :addTo(attack_button)
            local progress_2 = WidgetAllianceEnterButtonProgress.new()
                :pos(-68, -54)
                :addTo(strike_button)
        end
        buttons = {attack_button,strike_button}
    end
    else --我方占领
        if villageEvent:GetPlayerRole() == villageEvent.EVENT_PLAYER_ROLE.Me then --自己占领
            local che_button = self:BuildOneButton("capture_38x56.png",_("撤军")):onButtonClicked(function()

                    NetManager:getRetreatFromVillagePromise(villageEvent:VillageData().alliance.id,villageEvent:Id())
                    self:LeftButtonClicked()
            end)

        local info_button = self:BuildOneButton("icon_info_56x56.png",_("部队")):onButtonClicked(function()
            self:FindTroopShowInfoFromAllianceBelvedere()
            self:LeftButtonClicked()
        end)
        buttons =  {che_button,info_button}
    elseif villageEvent:GetPlayerRole() ==   villageEvent.EVENT_PLAYER_ROLE.Ally then --盟友占领
        local attack_button = self:BuildOneButton("capture_38x56.png",_("占领")):onButtonClicked(function()
            if self:CheckCanAttackVillage() then
                UIKit:newGameUI('GameUIAllianceSendTroops',function(dragonType,soldiers)
                    NetManager:getAttackVillagePromise(dragonType,soldiers,alliance_id,village_id):done(function()
                        app:GetAudioManager():PlayeEffectSoundWithKey("TROOP_SENDOUT")
                    end)
                end,{targetIsMyAlliance = self:IsMyAlliance(),toLocation = self:GetLogicPosition()}):AddToCurrentScene(true)
            end
            self:LeftButtonClicked()
        end)
    local strike_button = self:BuildOneButton("strike_66x62.png",_("突袭")):onButtonClicked(function()
        if self:CheckCanAttackVillage() then
            UIKit:newGameUI("GameUIStrikePlayer",{defenceAllianceId = alliance_id,defenceVillageId = village_id},GameUIStrikePlayer.STRIKE_TYPE.VILLAGE):AddToCurrentScene(true)
        end
        self:LeftButtonClicked()
    end)
    buttons = {attack_button,strike_button}
    end
    end
    return buttons
end

function GameUIAllianceVillageEnter:FindTroopShowInfoFromAllianceBelvedere()
    local village_id = self:GetVillageInfo().id
    local villageEvent = self:GetMyAlliance():FindVillageEventByVillageId(village_id)
    if villageEvent then
        if villageEvent:GetPlayerRole() == villageEvent.EVENT_PLAYER_ROLE.Me then
            local belvedereEntity = BelvedereEntity.new(villageEvent)
            belvedereEntity:SetType(BelvedereEntity.ENTITY_TYPE.COLLECT)
            UIKit:newGameUI("GameUIWatchTowerMyTroopsDetail",belvedereEntity):AddToCurrentScene(true)
        end
    end
end

function GameUIAllianceVillageEnter:OnMoveOutStage()
    self:GetMyAlliance():RemoveListenerOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventTimer)
    self:GetMyAlliance():RemoveListenerOnType(self,self:GetMyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    local alliance_map = self:GetMyAlliance():GetAllianceMap()
    alliance_map:RemoveListenerOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
    if self:HasEnemyAlliance() then
        local alliance_map = self:GetEnemyAlliance():GetAllianceMap()
        alliance_map:RemoveListenerOnType(self,alliance_map.LISTEN_TYPE.BUILDING)
        self:GetEnemyAlliance():RemoveListenerOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventTimer)
        self:GetEnemyAlliance():RemoveListenerOnType(self,self:GetEnemyAlliance().LISTEN_TYPE.OnVillageEventsDataChanged)
    end
    GameUIAllianceVillageEnter.super.OnMoveOutStage(self)
end
return GameUIAllianceVillageEnter

