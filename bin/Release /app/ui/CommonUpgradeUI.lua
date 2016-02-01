local SmallDialogUI = import(".SmallDialogUI")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local UpgradeBuilding = import("..entity.UpgradeBuilding")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")
local WidgetPushButton = import("..widget.WidgetPushButton")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetAccelerateGroup = import("..widget.WidgetAccelerateGroup")


local SpriteConfig = import("..sprites.SpriteConfig")


local CommonUpgradeUI = class("CommonUpgradeUI", function ()
    return display.newLayer()
end)

function CommonUpgradeUI:ctor(city,building)
    self:setNodeEventEnabled(true)
    self.city = city
    self.building = building
end

-- Node Event
function CommonUpgradeUI:onEnter()
    self:InitCommonPart()
    self:InitUpgradePart()
    self:InitAccelerationPart()
    local User = self.city:GetUser()
    User:AddListenOnType(self, "houseEvents")
    User:AddListenOnType(self, "buildingEvents")
    scheduleAt(self, function()
        if self.building:GetNextLevel() == self.building:GetLevel() then
            return
        end
        if self.upgrade_layer:isVisible() then
            self:SetUpgradeRequirementListview()
        end
        if self:GetCurrentEvent() then
            self:Upgrading()
        end
    end)
end

function CommonUpgradeUI:onExit()
    local User = self.city:GetUser()
    User:RemoveListenerOnType(self, "houseEvents")
    User:RemoveListenerOnType(self, "buildingEvents")
end
function CommonUpgradeUI:OnUserDataChanged_houseEvents(userData, deltaData)
    if City:IsFunctionBuilding(self.building) then
        return
    end
    local buildingLocation, houseLocation = self:GetCurrentLocation()
    local ok, value = deltaData("houseEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.buildingLocation == buildingLocation
                and v.houseLocation == houseLocation then
                self:UpgradeFinished()
            end
        end
    end
    local ok, value = deltaData("houseEvents.add")
    if ok then
        for i,v in ipairs(value) do
            if v.buildingLocation == buildingLocation
                and v.houseLocation == houseLocation then
                self:UpgradeBegin(v)
            end
        end
    end
end
function CommonUpgradeUI:OnUserDataChanged_buildingEvents(userData, deltaData)
    if not City:IsFunctionBuilding(self.building) then
        return
    end
    local buildingLocation = self:GetCurrentLocation()
    local ok, value = deltaData("buildingEvents.remove")
    if ok then
        for i,v in ipairs(value) do
            if v.location == buildingLocation then
                self:UpgradeFinished()
            end
        end
    end
    local ok, value = deltaData("buildingEvents.add")
    if ok then
        for i,v in ipairs(value) do
            if v.location == buildingLocation then
                self:UpgradeBegin(v)
            end
        end
    end
end
function CommonUpgradeUI:UpgradeBegin(event)
    local pro = self.acc_layer.ProgressTimer
    local time, percent = UtilsForEvent:GetEventInfo(event)
    self.acc_layer.upgrade_time_label:setString(GameUtils:formatTimeStyle1(time))
    pro:setPercentage(percent)
    self:visibleChildLayers()
end
function CommonUpgradeUI:UpgradeFinished()
    self:visibleChildLayers()
    self:SetBuildingLevel()
    self:SetUpgradeNowNeedGems()
    self:SetUpgradeTime()
    self:SetUpgradeEfficiency()
    self:ReloadBuildingImage()
    if self.building:GetNextLevel() == self.building:GetLevel() then
        self.upgrade_layer:setVisible(false)
    end
end
function CommonUpgradeUI:Upgrading()
    if City:IsFunctionBuilding(self.building) then
        local buildingLocation = self:GetCurrentLocation()
        local event = User:GetBuildingEventByLocation(buildingLocation)
        if event then
            local pro = self.acc_layer.ProgressTimer
            local time, percent = UtilsForEvent:GetEventInfo(event)
            self.acc_layer.upgrade_time_label:setString(GameUtils:formatTimeStyle1(time))
            pro:setPercentage(percent)
            self.acc_layer.acc_button:setButtonEnabled(
                DataUtils:getFreeSpeedUpLimitTime() >= time
            )
        end
    else
        local buildingLocation, houseLocation = self:GetCurrentLocation()
        local event = User:GetBuildingEventByLocation(buildingLocation, houseLocation)
        if event then
            local pro = self.acc_layer.ProgressTimer
            local time, percent = UtilsForEvent:GetEventInfo(event)
            self.acc_layer.upgrade_time_label:setString(GameUtils:formatTimeStyle1(time))
            pro:setPercentage(percent)
            self.acc_layer.acc_button:setButtonEnabled(
                DataUtils:getFreeSpeedUpLimitTime() >= time
            )
        end
    end
end
function CommonUpgradeUI:GetCurrentEvent()
    return User:GetBuildingEventByLocation(self:GetCurrentLocation())
end
function CommonUpgradeUI:GetCurrentLocation()
    if self.building:GetType() == "wall" then
        return 21
    elseif self.building:GetType() == "tower" then
        return 22
    end
    local tile = City:GetTileWhichBuildingBelongs(self.building)
    if City:IsFunctionBuilding(self.building) then
        return tile.location_id
    else
        local houseLocation = tile:GetBuildingLocation(self.building)
        return tile.location_id, houseLocation
    end
end
function CommonUpgradeUI:InitCommonPart()
    -- building level
    local level_bg = display.newScale9Sprite("title_blue_430x30.png",display.cx+80, display.top-125, cc.size(390,30), cc.rect(10,10,410,10)):addTo(self)
    self.builging_level = UIKit:ttfLabel({
        font = UIKit:getFontFilePath(),
        size = 26,
        color = 0xffedae,
        bold = true
    }):align(display.LEFT_CENTER, 20, level_bg:getContentSize().height/2)
        :addTo(level_bg)
    -- 建筑功能介绍
    WidgetPushButton.new({normal = "alliance_item_flag_box_126X126.png"})
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                UIKit:newGameUI("GameUICityBuildingInfo", self.building):AddToCurrentScene(true)
            end
        end):align(display.CENTER, display.cx-200, display.top-175)
        :addTo(self):scale(136/126)
    display.newSprite("info_26x26.png"):addTo(self,2):align(display.LEFT_BOTTOM, display.cx-264, display.top-240)
    self:ReloadBuildingImage()
    -- self:InitBuildingIntroduces()
    self:SetUpgradeEfficiency()
    self:SetBuildingLevel()
end
function CommonUpgradeUI:ReloadBuildingImage()
    if self.building_image then
        self.building_image:removeFromParent()
    end
    local config = SpriteConfig[self.building:GetType()]:GetConfigByLevel(self.building:GetLevel())
    local configs = SpriteConfig[self.building:GetType()]:GetAnimationConfigsByLevel(self.building:GetLevel())
    self.building_image = display.newSprite(config.png, 0, 0)
        :addTo(self):pos(display.cx-196, display.top-164)
    local p = self.building_image:getAnchorPointInPoints()
    for _,v in ipairs(configs) do
        if v.deco_type == "image" then
            display.newSprite(v.deco_name):addTo(self.building_image)
                :pos(p.x + v.offset.x, p.y + v.offset.y)
        elseif v.deco_type == "animation" then
            local offset = v.offset
            local armature = ccs.Armature:create(v.deco_name)
                :addTo(self.building_image):scale(v.scale or 1)
                :align(display.CENTER, offset.x or p.x, offset.y or p.y)
            armature:getAnimation():setSpeedScale(2)
            armature:getAnimation():playWithIndex(0)
        end
    end
    if self.building:GetType()=="watchTower" or self.building:GetType()=="tower" then
        self.building_image:setScale(150/self.building_image:getContentSize().height)
    else
        self.building_image:setScale(124/self.building_image:getContentSize().width)
    end
end

function CommonUpgradeUI:SetBuildingLevel()
    self.builging_level:setString(_("等级 ")..self.building:GetLevel())
    if self.building:GetNextLevel() == self.building:GetLevel() then
        -- self.next_level:getParent():setVisible(false)
        local bg = display.newSprite("back_ground_608x350.png"):align(display.CENTER_BOTTOM, window.cx, window.bottom_top + 10):addTo(self)
        -- npc image
        display.newSprite("Npc.png"):align(display.LEFT_BOTTOM, -50, -14):addTo(bg)
        -- 对话框 bg
        local tip_bg = display.newSprite("back_ground_342x228.png", 406,210):addTo(bg)
        -- 称谓label
        cc.ui.UILabel.new({
            UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
            text = _("当前建筑已达最大等级"),
            font = UIKit:getFontFilePath(),
            size = 24,
            color = UIKit:hex2c3b(0x403c2f)
        }):align(display.LEFT_TOP,14,210):addTo(tip_bg)
        -- else
        -- self.next_level:setString(_("等级 ")..self.building:GetNextLevel())
    end
end

-- function CommonUpgradeUI:InitBuildingIntroduces()
--     self.building_introduces = UIKit:ttfLabel({
--         size = 18,
--         dimensions = cc.size(380, 0),
--         color = 0x615b44
--     }):align(display.LEFT_TOP,display.cx-110, display.top-150):addTo(self)

--     self:SetBuildingIntroduces()
-- end
-- function CommonUpgradeUI:SetBuildingIntroduces()
--     local bd = Localize.building_description
--     self.building_introduces:setString(bd[self.building:GetType()])
-- end


-- function CommonUpgradeUI:InitNextLevelEfficiency()
-- 下一级 框
-- local bg  = display.newSprite("upgrade_next_level_bg.png", window.left+114, window.top-310):addTo(self)
-- local bg_size = bg:getContentSize()
-- self.next_level = UIKit:ttfLabel({
--     size = 20,
--     color = 0x403c2f
-- }):align(display.CENTER,bg_size.width/2,bg_size.height/2):addTo(bg)

-- local efficiency_bg = display.newSprite("back_ground_398x97.png", window.cx+74, window.top-310):addTo(self)
-- self.intro_list = UIListView.new({
--     direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
--     viewRect = cc.rect(10,8,380,80),
-- }):addTo(efficiency_bg)

-- self:SetUpgradeEfficiency()
-- end

function CommonUpgradeUI:SetUpgradeEfficiency()
    if not self.eff_node then
        local eff_node = display.newNode():addTo(self)
        eff_node:setContentSize(cc.size(384,240))
        eff_node:align(display.LEFT_TOP,display.cx - 110, display.top - 150)
        local parent = self
        function eff_node:AddItem( title, current, eff )
            local line_width = 384
            local line = display.newScale9Sprite("dividing_line.png",0,0,cc.size(line_width,2),cc.rect(10,2,382,2))
            local title_label = UIKit:ttfLabel({
                text = title,
                size = 20,
                color = 0x615b44,
            }):align(display.LEFT_BOTTOM, 10 , 2)
                :addTo(line)

            local current_label = UIKit:ttfLabel({
                text = current,
                size = 22,
                color = 0x403c2f,
            }):addTo(line)
            local eff_text

            if tolua.type(eff) == "string" then
                eff_text = (eff ~= "" and eff ~= "0" and " + " or "" ).. (eff == "0" and "" or eff)
            elseif tolua.type(eff) == "number" then
                if eff == 0 then
                    eff_text = ""
                else
                    eff_text = " + "..eff
                end
            end
            local eff_label = UIKit:ttfLabel({
                text = eff_text,
                size = 22,
                color = 0x068329,
            }):addTo(line)

            local eff_width = eff_label:getContentSize().width
            eff_label:align(display.RIGHT_BOTTOM, line_width - 10, 2)
            current_label:align(display.RIGHT_BOTTOM, eff_label:getPositionX() - eff_width , 2)


            local items = self.items or 1
            line:align(display.LEFT_BOTTOM,0,240 - 30 * items):addTo(self)
            self.items = items + 1
        end
        self.eff_node = eff_node
    end
    local eff_node = self.eff_node
    eff_node.items = nil
    eff_node:removeAllChildren()

    local bd = Localize.building_description
    local building = self.building
    local efficiency = ""
    local formatNumber = string.formatnumberthousands
    if building:GetType() == "keep" then
        eff_node:AddItem( bd.unlock, building:GetUnlockPoint(), building:GetNextLevelUnlockPoint() - building:GetUnlockPoint() )
        eff_node:AddItem( bd.beHelpCount, building:GetBeHelpedCount(), building:GetNextLevelBeHelpedCount() - building:GetBeHelpedCount() )
        -- local unlock_point = building:GetNextLevelUnlockPoint() - building:GetUnlockPoint()
        -- if unlock_point > 0 then
        --     efficiency = efficiency..string.format("%s+%d,",bd.unlock,unlock_point)
        -- end
        -- local be_helped_count = building:GetNextLevelBeHelpedCount()-building:GetBeHelpedCount()
        -- if be_helped_count>0 then
        --     efficiency = efficiency.. string.format("%s+%d,",bd.beHelpCount,be_helped_count)
        -- end
    elseif self.building:GetType()=="dragonEyrie" then
        eff_node:AddItem( bd.vitalityRecoveryPerHour, formatNumber(building:GetHPRecoveryPerHourWithoutBuff()), formatNumber(building:GetNextLevelHPRecoveryPerHour() - building:GetHPRecoveryPerHourWithoutBuff()) )
        -- local additon = building:GetNextLevelHPRecoveryPerHour()-building:GetHPRecoveryPerHourWithoutBuff()
        -- if additon>0 then
        --     efficiency = efficiency .. string.format("%s+%d,",bd.vitalityRecoveryPerHour,additon)
        -- end
    elseif self.building:GetType()=="watchTower" then
        local warning = GameDatas.ClientInitGame.watchTower
        efficiency = string.format(bd["watchTower_"..self.building:GetLevel()],warning[self.building:GetLevel()].waringMinute)
        UIKit:ttfLabel({
            text = efficiency,
            size = 18,
            dimensions = cc.size(380, 0),
            color = 0x615b44
        }):align(display.LEFT_TOP,0,240):addTo(eff_node)
    elseif self.building:GetType()=="warehouse" then
        eff_node:AddItem( bd.warehouse_max, formatNumber(building:GetResourceValueLimit()), formatNumber(building:GetResourceNextLevelValueLimit() - building:GetResourceValueLimit()) )
        -- local additon = building:GetResourceNextLevelValueLimit()-building:GetResourceValueLimit()
        -- if additon>0 then
        --     efficiency = string.format("%s+%s,",bd.warehouse_max,string.formatnumberthousands(additon))
        -- end
    elseif self.building:GetType()=="toolShop" then
        eff_node:AddItem( bd.poduction, formatNumber(building:GetProduction()), formatNumber(building:GetNextLevelProduction() - building:GetProduction()) )
        eff_node:AddItem( _("一次随机制造种类"), formatNumber(building:GetProductionType()), formatNumber(building:GetNextLevelProductionType() - building:GetProductionType()) )
        eff_node:AddItem( _("制造材料资源消耗降低"), ((building:GetLevel() - 1) * 0.5 + (building:IsMaxLevel() and 0.5 or 0)).."%", building:IsMaxLevel() and "" or building:GetLevel() == 39 and "1%" or "0.5%" )

        -- local additon = building:GetNextLevelProduction()-building:GetProduction()
        -- if additon>0 then
        --     efficiency = string.format("%s+%d,",bd.poduction,additon)
        -- end
        -- local additon = building:GetNextLevelProductionType()-building:GetProductionType()
        -- if additon>0 then
        --     efficiency = efficiency..string.format(_("一次随机制造种类+%d,"),additon)
        -- end
        -- if self.building:GetLevel() == 39 then
        --     efficiency = efficiency .. string.format(_("制造材料资源消耗降低%.1f%%,"),1.0)
        -- else
        --     efficiency = efficiency .. string.format(_("制造材料资源消耗降低%.1f%%,"),0.5)
        -- end
    elseif self.building:GetType()=="materialDepot" then
        eff_node:AddItem( bd.maxMaterial, formatNumber(building:GetMaxMaterial()), formatNumber(building:GetNextLevelMaxMaterial() - building:GetMaxMaterial()) )
        -- local additon = building:GetNextLevelMaxMaterial()-building:GetMaxMaterial()
        -- if additon>0 then
        --     efficiency = string.format("%s+%d,",bd.maxMaterial,additon)
        -- end
    elseif self.building:GetType()=="barracks" then
        eff_node:AddItem( bd.maxRecruit, formatNumber(building:GetMaxRecruitSoldierCount()), formatNumber(building:GetNextLevelMaxRecruitSoldierCount() - building:GetMaxRecruitSoldierCount()) )
        -- local additon = building:GetNextLevelMaxRecruitSoldierCount()-building:GetMaxRecruitSoldierCount()
        -- if additon>0 then
        --     efficiency = string.format("%s+%d,",bd.maxRecruit,additon)
        -- end
    elseif self.building:GetType()=="blackSmith" then
        local added = building:GetNextLevelEfficiency() - building:GetEfficiency()
        eff_node:AddItem( bd.blackSmith_efficiency, (building:GetEfficiency()*100).."%", added > 0 and added * 100 .. "%" or "")
        -- local additon = (building:GetNextLevelEfficiency()-building:GetEfficiency())*100
        -- if additon>0 then
        --     efficiency = string.format("%s+%.1f%%,",bd.blackSmith_efficiency,additon)
        -- end
    elseif self.building:GetType()=="foundry" then
        eff_node:AddItem( bd.foundry_miner, formatNumber(building:GetNextLevelMaxHouseNum()), formatNumber(building:GetNextLevelMaxHouseNum() - building:GetMaxHouseNum()) )
        local added = building:GetNextLevelProtection() - building:GetProtection()
        eff_node:AddItem( bd.foundry_protection, (building:GetProtection()*100).."%", added > 0 and added * 100 .. "%" or "" )
        -- local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        -- efficiency = ""
        -- if house_add>0 then
        --     efficiency = string.format("%s+%d," ,bd.foundry_miner,house_add)
        -- end
        -- local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        -- if addtion>0 then
        --     efficiency = efficiency..string.format("%s+%.1f%%,",bd.foundry_protection,addtion)
        -- end
    elseif self.building:GetType()=="lumbermill" then
        eff_node:AddItem( bd.lumbermill_woodcutter, formatNumber(building:GetMaxHouseNum()), formatNumber(building:GetNextLevelMaxHouseNum() - building:GetMaxHouseNum()) )
        local added = building:GetNextLevelProtection() - building:GetProtection()
        eff_node:AddItem( bd.lumbermill_protection, (building:GetProtection()*100).."%",  added > 0 and added * 100 .. "%" or "")
        -- local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        -- efficiency = ""
        -- if house_add>0 then
        --     efficiency = string.format("%s+%d," ,bd.lumbermill_woodcutter,house_add)
        -- end
        -- local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        -- if addtion>0 then
        --     efficiency = efficiency..string.format("%s+%.1f%%,",bd.lumbermill_protection,addtion)
        -- end
    elseif self.building:GetType()=="mill" then
        eff_node:AddItem( bd.mill_farmer, formatNumber(building:GetMaxHouseNum()), formatNumber(building:GetNextLevelMaxHouseNum() - building:GetMaxHouseNum()) )
        local added = building:GetNextLevelProtection() - building:GetProtection()
        eff_node:AddItem( bd.mill_protection, (building:GetProtection()*100).."%", added > 0 and added * 100 .. "%" or "")

        -- local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        -- efficiency = ""
        -- if house_add>0 then
        --     efficiency = string.format("%s+%d," ,bd.mill_farmer,house_add)
        -- end
        -- local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        -- if addtion>0 then
        --     efficiency = efficiency..string.format("%s+%.1f%%,",bd.mill_protection,addtion)
        -- end
    elseif self.building:GetType()=="stoneMason" then
        eff_node:AddItem( bd.stoneMason_quarrier, formatNumber(building:GetMaxHouseNum()), formatNumber(building:GetNextLevelMaxHouseNum() - building:GetMaxHouseNum()) )
        local added = building:GetNextLevelProtection() - building:GetProtection()
        eff_node:AddItem( bd.stoneMason_protection, (building:GetProtection()*100).."%", added > 0 and added * 100 .. "%" or "" )

        -- local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        -- efficiency = ""
        -- if house_add>0 then
        --     efficiency = string.format("%s+%d," ,bd.stoneMason_quarrier,house_add)
        -- end
        -- local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        -- if addtion>0 then
        --     efficiency = efficiency..string.format("%s+%.1f%%,",bd.stoneMason_protection,addtion)
        -- end
    elseif self.building:GetType()=="hospital" then
        eff_node:AddItem( bd.maxCasualty, formatNumber(building:GetMaxCasualty()), formatNumber(building:GetNextLevelMaxCasualty() - building:GetMaxCasualty()) )

        -- local addtion = building:GetNextLevelMaxCasualty()-building:GetMaxCasualty()
        -- if addtion>0 then
        --     efficiency = string.format("%s+%d,",bd.maxCasualty,addtion)
        -- end
    elseif self.building:GetType()=="townHall" then
        eff_node:AddItem( bd.townHall_dwelling, formatNumber(building:GetMaxHouseNum()), formatNumber(building:GetNextLevelMaxHouseNum() - building:GetMaxHouseNum()) )
        local added = building:GetNextLevelEfficiency() - building:GetEfficiency()
        eff_node:AddItem( _("提升任务奖励"), (building:GetEfficiency()*100).."%", added > 0 and added * 100 .. "%" or ""  )
        -- local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        -- efficiency = ""
        -- if house_add>0 then
        --     efficiency = string.format("%s+%d," ,bd.townHall_dwelling,house_add)
        -- end
        -- local award_add = (building:GetNextLevelEfficiency() - building:GetEfficiency()) * 100
        -- if award_add > 0 then
        --     efficiency = efficiency .. string.format("%s+%d%%," ,_("提升任务奖励"),award_add)
        -- end
    elseif self.building:GetType()=="dwelling" then
        eff_node:AddItem( bd.dwelling_citizen, formatNumber(building:GetProductionLimit()), formatNumber(building:GetNextLevelCitizen() - building:GetProductionLimit()) )
        eff_node:AddItem( bd.dwelling_poduction, formatNumber(building:GetProductionPerHour()), formatNumber(building:GetNextLevelProductionPerHour() - building:GetProductionPerHour()) )
        -- local addtion = building:GetNextLevelCitizen()-building:GetProductionLimit()
        -- if addtion>0 then
        --     efficiency = string.format("%s+%d,",bd.dwelling_citizen,addtion)
        -- end
        -- local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        -- if addtion>0 then
        --     efficiency = efficiency..string.format("%s+%d,",bd.dwelling_poduction,addtion)
        -- end
    elseif self.building:GetType()=="woodcutter" then
        eff_node:AddItem( bd.woodcutter_poduction, formatNumber(building:GetProductionPerHour()), formatNumber(building:GetNextLevelProductionPerHour() - building:GetProductionPerHour()) )
        -- local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        -- if addtion>0 then
        --     efficiency = string.format("%s+%d,",bd.woodcutter_poduction,addtion)
        -- end
    elseif self.building:GetType()=="farmer" then
        eff_node:AddItem( bd.farmer_poduction, formatNumber(building:GetProductionPerHour()), formatNumber(building:GetNextLevelProductionPerHour() - building:GetProductionPerHour()) )
        -- local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        -- if addtion>0 then
        --     efficiency = string.format("%s+%d,",bd.farmer_poduction,addtion)
        -- end
    elseif self.building:GetType()=="quarrier" then
        eff_node:AddItem( bd.quarrier_poduction, formatNumber(building:GetProductionPerHour()), formatNumber(building:GetNextLevelProductionPerHour() - building:GetProductionPerHour()) )
        -- local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        -- if addtion>0 then
        --     efficiency = string.format("%s+%d,",bd.quarrier_poduction,addtion)
        -- end
    elseif self.building:GetType()=="miner" then
        eff_node:AddItem( bd.miner_poduction, formatNumber(building:GetProductionPerHour()), formatNumber(building:GetNextLevelProductionPerHour() - building:GetProductionPerHour()) )
        -- local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        -- if addtion>0 then
        --     efficiency = string.format("%s+%d,",bd.miner_poduction,addtion)
        -- end
    elseif self.building:GetType()=="wall" then
        local current_config = self.building:GetWallConfig()
        local next_config = self.building:GetWallNextLevelConfig()
        eff_node:AddItem( _("城墙血量"),formatNumber(current_config.wallHp),formatNumber(next_config.wallHp - current_config.wallHp) )
        eff_node:AddItem( _("城墙血量每小时回复"),current_config.wallRecovery,next_config.wallRecovery - current_config.wallRecovery)
        -- if next_config.wallHp - current_config.wallHp > 0 then
        --     efficiency = string.format(_("城墙血量+%d,"),next_config.wallHp - current_config.wallHp)
        -- end
        -- if next_config.wallRecovery - current_config.wallRecovery > 0 then
        --     efficiency = efficiency .. string.format(_("城墙血量回复+%d/小时,"),next_config.wallRecovery - current_config.wallRecovery)
        -- end
    elseif self.building:GetType()=="tower" then
        local current_config = self.building:GetTowerConfig()
        local next_config = self.building:GetTowerNextLevelConfig()
        eff_node:AddItem( _("攻击"),formatNumber(current_config.infantry),formatNumber(next_config.infantry - current_config.infantry) )
        eff_node:AddItem( _("防御力"),formatNumber(current_config.defencePower),formatNumber(next_config.defencePower - current_config.defencePower) )
        -- if next_config.infantry - current_config.infantry > 0 then
        --     efficiency = string.format(_("攻击+%d,"),next_config.infantry - current_config.infantry)
        -- end
        -- if next_config.defencePower - current_config.defencePower > 0 then
        --     efficiency = efficiency .. string.format(_("防御力+%d,"),next_config.defencePower - current_config.defencePower)
        -- end
    elseif self.building:GetType()=="academy" then
        local current_config = self.building:GetAcademyConfig()
        local next_config = self.building:GetAcademyNextLevelConfig()
        local added = next_config.efficiency - current_config.efficiency
        eff_node:AddItem( _("学院科技研发速度"),current_config.efficiency * 100, added > 0 and (added * 100) .. "%" or "" )
        -- if next_config.efficiency - current_config.efficiency > 0 then
        --     efficiency = string.format(_("学院科技研发速度+%d%%,"),(next_config.efficiency - current_config.efficiency)*100)
        -- end
    elseif self.building:GetType()=="tradeGuild" then
        local cart = self.building:GetMaxCart()
        local next_cart = self.building:GetNextLevelMaxCart()
        local recovery = self.building:GetCartRecovery()
        local next_recovery = self.building:GetNextLevelCartRecovery()
        eff_node:AddItem( _("资源小车上限"),formatNumber(cart), formatNumber(next_cart - cart) )
        eff_node:AddItem( _("资源小车每小时回复速度"),formatNumber(recovery), formatNumber(next_recovery - recovery) )
        -- if next_cart - cart > 0 then
        --     efficiency = string.format(_("资源小车上限+%d,"),(next_cart - cart))
        -- end
        -- if next_recovery - recovery > 0 then
        --     efficiency = efficiency .. string.format(_("资源小车回复速度+%d/小时,"),(next_recovery - recovery))
        -- end
    elseif self.building:GetType()=="trainingGround" then
        local eff = self.building:GetEfficiency()
        local next_eff = self.building:GetNextLevelEfficiency()
        local added = next_eff - eff
        eff_node:AddItem( _("步兵招募速度"),eff * 100 .. "%", added > 0 and (added * 100) .. "%" or ""  )
        -- if next_eff - eff > 0 then
        --     efficiency = string.format(_("步兵招募速度+%.0f%%,"),(next_eff - eff) * 100)
        -- end
    elseif self.building:GetType()=="stable" then
        local eff = self.building:GetEfficiency()
        local next_eff = self.building:GetNextLevelEfficiency()
        local added = next_eff - eff
        eff_node:AddItem( _("骑兵招募速度"),eff * 100 .. "%", added > 0 and (added * 100) .. "%" or ""  )
        -- if next_eff - eff > 0 then
        --     efficiency = string.format(_("骑兵招募速度+%.0f%%,"),(next_eff - eff) * 100)
        -- end
    elseif self.building:GetType()=="hunterHall" then
        local eff = self.building:GetEfficiency()
        local next_eff = self.building:GetNextLevelEfficiency()
        local added = next_eff - eff
        eff_node:AddItem( _("弓手招募速度"),eff * 100 .. "%", added > 0 and (added * 100) .. "%" or ""  )
        -- if next_eff - eff > 0 then
        --     efficiency = string.format(_("弓手招募速度+%.0f%%,"),(next_eff - eff) * 100)
        -- end
    elseif self.building:GetType()=="workshop" then
        local eff = self.building:GetEfficiency()
        local next_eff = self.building:GetNextLevelEfficiency()
        local added = next_eff - eff
        eff_node:AddItem( _("攻城系招募速度"),eff * 100 .. "%", added > 0 and (added * 100) .. "%" or ""  )
        -- if next_eff - eff > 0 then
        --     efficiency = string.format(_("攻城系招募速度+%.0f%%,"),(next_eff - eff) * 100)
        -- end
    else
        assert(false,"本地化丢失")
    end
    -- 增加power,每个建筑都有的属性
    if building:GetType()~="watchTower" then
        eff_node:AddItem(bd.power,formatNumber(building:GetPower()), formatNumber(building:GetNextLevelPower()-building:GetPower()))
    end
    -- efficiency = efficiency ..string.format("%s+%d",bd.power,building:GetNextLevelPower()-building:GetPower())
    -- local efficiency_content = UIKit:ttfLabel({
    --     text = efficiency,
    --     size = 20,
    --     dimensions = cc.size(370,0),
    --     valign = cc.ui.UILabel.TEXT_VALIGN_CENTER,
    --     align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
    --     color = 0x403c2f
    -- })
    -- efficiency_content:setLineBreakWithoutSpace(true)
    -- local list = self.intro_list
    -- list:removeAllItems()
    -- local item = list:newItem()
    -- item:setItemSize(370, efficiency_content:getContentSize().height)
    -- item:addContent(efficiency_content)
    -- list:addItem(item)
    -- list:reload()
    -- if self.building:GetNextLevel() == self.building:GetLevel() then
    --     list:getParent():setVisible(false)
    -- end
end

function CommonUpgradeUI:InitUpgradePart()
    -- 升级页
    if self.building:GetNextLevel() == self.building:GetLevel() then
        return
    end
    self.upgrade_layer = display.newLayer()
    self.upgrade_layer:setContentSize(cc.size(display.width,710))
    self:addChild(self.upgrade_layer)
    -- upgrade now button
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即升级")},
            listener = function ()
                local commend = function ()
                    local upgrade_listener = function()
                        if self.building:GetType()=="tower" then
                            NetManager:getInstantUpgradeTowerPromise():done(function()
                                self:UpgradeFinished()
                            end)
                        elseif self.building:GetType()=="wall" then
                            NetManager:getInstantUpgradeWallByLocationPromise():done(function()
                                self:UpgradeFinished()
                            end)
                        else
                            if City:IsFunctionBuilding(self.building) then
                                NetManager:getInstantUpgradeBuildingByLocationPromise(self:GetCurrentLocation()):done(function()
                                    self:UpgradeFinished()
                                end)
                            else
                                local l1, l2 = self:GetCurrentLocation()
                                NetManager:getInstantUpgradeHouseByLocationPromise(l1, l2):done(function()
                                    self:UpgradeFinished()
                                end)
                            end
                        end
                    end

                    local can_not_update_type = self.building:IsAbleToUpgrade(true)
                    if can_not_update_type then
                        self:PopNotSatisfyDialog(upgrade_listener,can_not_update_type)
                    else
                        upgrade_listener()
                    end
                end

                if app:GetGameDefautlt():IsOpenGemRemind() then
                    UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                        string.formatnumberthousands(self.building:getUpgradeNowNeedGems())
                    ), function()
                        commend()
                    end,true,true)
                else
                    commend()
                end
            end,
        }
    ):pos(display.cx-150, display.top-330)
        :addTo(self.upgrade_layer)

    -- upgrade button
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams={text = _("升级")},
            listener = function ()
                local upgrade_listener = function()
                    if self.building:GetType()=="tower" then
                        NetManager:getUpgradeTowerPromise()
                    elseif self.building:GetType()=="wall" then
                        NetManager:getUpgradeWallByLocationPromise()
                    else
                        if City:IsFunctionBuilding(self.building) then
                            NetManager:getUpgradeBuildingByLocationPromise(self:GetCurrentLocation())
                        else
                            NetManager:getUpgradeHouseByLocationPromise(self:GetCurrentLocation())
                        end
                    end
                    self:getParent():getParent():LeftButtonClicked()
                end

                local can_not_update_type = self.building:IsAbleToUpgrade(false)
                if can_not_update_type then
                    self:PopNotSatisfyDialog(upgrade_listener,can_not_update_type)
                else
                    upgrade_listener()
                end
            end,
        }
    ):pos(display.cx+180, display.top-330)
        :addTo(self.upgrade_layer)

    self.upgrade_btn = btn_bg.button

    -- 立即升级所需金龙币
    display.newSprite("gem_icon_62x61.png", display.cx - 260, display.top-390):addTo(self.upgrade_layer):setScale(0.5)
    self.upgrade_now_need_gems_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,display.cx - 240,display.top-394):addTo(self.upgrade_layer)
    self:SetUpgradeNowNeedGems()
    --升级所需时间
    display.newSprite("hourglass_30x38.png", display.cx+100, display.top-390):addTo(self.upgrade_layer):setScale(0.6)
    self.upgrade_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,display.cx+125,display.top-380):addTo(self.upgrade_layer)

    -- 科技减少升级时间
    self.buff_reduce_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "(-00:20:00)",
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x068329)
    }):align(display.LEFT_CENTER,display.cx+120,display.top-400):addTo(self.upgrade_layer)

    self:SetUpgradeTime()
    --升级需求listview
    self:SetUpgradeRequirementListview()



    -- TODO
    self:visibleChildLayers()

    -- self.upgrade_layer:setVisible(false)
end

function CommonUpgradeUI:SetUpgradeNowNeedGems()
    self.upgrade_now_need_gems_label:setString(self.building:getUpgradeNowNeedGems().."")
end

function CommonUpgradeUI:SetUpgradeTime()
    self.upgrade_time:setString(GameUtils:formatTimeStyle1(self.building:GetUpgradeTimeToNextLevel()))
    local buff_time = DataUtils:getBuildingBuff(self.building:GetUpgradeTimeToNextLevel())
    self.buff_reduce_time:setString(string.format("(-%s)",GameUtils:formatTimeStyle1(buff_time)))
end
function CommonUpgradeUI:GotoPreconditionBuilding()
    local jump_building = self.building:GetPreConditionBuilding()
    UIKit:GotoPreconditionBuilding(jump_building)
    self:getParent():getParent():LeftButtonClicked()
end
function CommonUpgradeUI:SetUpgradeRequirementListview()
    local city = City
    local User = User
    local wood = User:GetResValueByType("wood")
    local iron = User:GetResValueByType("iron")
    local stone = User:GetResValueByType("stone")
    local citizen = User:GetResValueByType("citizen")
    local materials = User.buildingMaterials
    local building = self.building
    local pre_condition = building:IsBuildingUpgradeLegal()
    local requirements = {
        {
            resource_type = _("前置条件"),
            isVisible = building:GetLevel()>5 and building:GetType() ~= "dragonEyrie",
            isSatisfy = not pre_condition,canNotBuy=true,
            icon="hammer_33x40.png",
            description = building:GetPreConditionDesc(),jump_call = handler(self,self.GotoPreconditionBuilding)
        },
        {
            resource_type = "building_queue",
            isVisible = #city:GetUpgradingBuildings() >= User.basicInfo.buildQueue,
            isSatisfy = #city:GetUpgradingBuildings()  < User.basicInfo.buildQueue,
            icon="hammer_33x40.png",
            description=_("建造队列已满")..(User.basicInfo.buildQueue-#city:GetUpgradingBuildings()).."/"..User.basicInfo.buildQueue
        },
        {
            resource_type = _("木材"),
            isVisible = building:GetLevelUpWood()>0,
            isSatisfy = wood>=building:GetLevelUpWood(),
            icon="res_wood_82x73.png",
            description=wood.."/"..building:GetLevelUpWood()
        },
        {
            resource_type = _("石料"),
            isVisible = building:GetLevelUpStone()>0,
            isSatisfy = stone>=building:GetLevelUpStone() ,
            icon="res_stone_88x82.png",
            description=stone.."/"..building:GetLevelUpStone()
        },

        {
            resource_type = _("铁矿"),
            isVisible = building:GetLevelUpIron()>0,
            isSatisfy = iron>=building:GetLevelUpIron() ,
            icon="res_iron_91x63.png",
            description=iron.."/"..building:GetLevelUpIron()
        },

        {
            resource_type = _("空闲城民"),
            isVisible = building:GetLevelUpCitizen()>0,
            isSatisfy = citizen>=building:GetLevelUpCitizen() ,
            icon="res_citizen_88x82.png",
            description=citizen.."/"..building:GetLevelUpCitizen()
        },

        {
            resource_type = _("工程图纸"),
            isVisible = building:GetLevelUpBlueprints()>0,
            isSatisfy = materials["blueprints"]>=building:GetLevelUpBlueprints() ,
            icon="blueprints_128x128.png",
            description=materials["blueprints"].."/"..building:GetLevelUpBlueprints()
        },
        {
            resource_type = _("建造工具"),
            isVisible = building:GetLevelUpTools()>0,
            isSatisfy = materials["tools"]>=building:GetLevelUpTools() ,
            icon="tools_128x128.png",
            description=materials["tools"].."/"..building:GetLevelUpTools()
        },
        {
            resource_type =_("砖石瓦片"),
            isVisible = building:GetLevelUpTiles()>0,
            isSatisfy = materials["tiles"]>=building:GetLevelUpTiles() ,
            icon="tiles_128x128.png",
            description=materials["tiles"].."/"..building:GetLevelUpTiles()
        },
        {
            resource_type = _("滑轮组"),
            isVisible = building:GetLevelUpPulley()>0,
            isSatisfy = materials["pulley"]>=building:GetLevelUpPulley() ,
            icon="pulley_128x128.png",
            description=materials["pulley"].."/"..building:GetLevelUpPulley()
        },
    }

    if not self.requirement_listview then
        self.requirement_listview = WidgetRequirementListview.new({
            title = _("升级需求"),
            height = 386,
            contents = requirements,
        }):addTo(self.upgrade_layer):pos(display.cx-272, display.top-860)
    end
    self.requirement_listview:RefreshListView(requirements)
end

function CommonUpgradeUI:InitAccelerationPart()
    if self.building:GetNextLevel() == self.building:GetLevel() then
        return
    end
    self.acc_layer = display.newLayer()
    self.acc_layer:setContentSize(cc.size(display.width,680))
    self:addChild(self.acc_layer)

    -- 正在升级文本说明
    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = string.format(_("正在升级 %s 到等级 %d"),Localize.building_name[self.building:GetType()],self.building:GetLevel()+1),
        font = UIKit:getFontFilePath(),
        size = 22,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER, display.cx - 260, display.top - 305)
        :addTo(self.acc_layer)
    -- 升级倒数时间进度条
    --进度条
    local bar = display.newSprite("progress_bar_364x40_1.png"):addTo(self.acc_layer):pos(display.cx-78, display.top - 345)
    local progressFill = display.newSprite("progress_bar_364x40_2.png")
    self.acc_layer.ProgressTimer = cc.ProgressTimer:create(progressFill)
    local pro = self.acc_layer.ProgressTimer
    pro:setType(display.PROGRESS_TIMER_BAR)
    pro:setBarChangeRate(cc.p(1,0))
    pro:setMidpoint(cc.p(0,0))
    pro:align(display.LEFT_BOTTOM, 0, 0):addTo(bar)
    pro:setPercentage(0)
    self.acc_layer.upgrade_time_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        -- text = "",
        font = UIKit:getFontFilePath(),
        size = 18,
        align = ui.TEXT_ALIGN_CENTER,
        color = UIKit:hex2c3b(0xfff3c7),
    }):addTo(bar)
    self.acc_layer.upgrade_time_label:setAnchorPoint(cc.p(0,0.5))
    self.acc_layer.upgrade_time_label:pos(self.acc_layer.upgrade_time_label:getContentSize().width/2+40, bar:getContentSize().height/2)
    local event = self:GetCurrentEvent()
    if event then
        local time, percent = UtilsForEvent:GetEventInfo(event)
        self.acc_layer.upgrade_time_label
            :setString(GameUtils:formatTimeStyle1(time))
        pro:setPercentage(percent)
    end

    -- 进度条头图标
    display.newSprite("back_ground_43x43.png", display.cx - 250, display.top - 345):addTo(self.acc_layer)
    display.newSprite("hourglass_30x38.png", display.cx - 250, display.top - 345):addTo(self.acc_layer):setScale(0.8)
    -- 免费加速按钮
    self:CreateFreeSpeedUpBuildingUpgradeButton()
    -- 可免费加速提示
    -- 背景框
    WidgetUIBackGround.new({width = 546,height=90},WidgetUIBackGround.STYLE_TYPE.STYLE_3):align(display.CENTER,  display.cx, display.top - 435):addTo(self.acc_layer)
    self.acc_tip_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        dimensions = cc.size(530, 0),
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER, display.cx - 270, display.top - 435)
        :addTo(self.acc_layer)
    self:SetAccTipLabel()
    -- 按时间加速区域
    self:CreateAccButtons()
    self:visibleChildLayers()

end

function CommonUpgradeUI:CreateFreeSpeedUpBuildingUpgradeButton()
    local  IMAGES  = {
        normal = "purple_btn_up_148x76.png",
        pressed = "purple_btn_down_148x76.png",
    }
    self.acc_layer.acc_button = WidgetPushButton.new(IMAGES, {scale9 = false},
        {
            disabled = { name = "GRAY", params = {0.2, 0.3, 0.5, 0.1} }
        })
        :setButtonLabel(UIKit:commonButtonLable({text = _("免费加速")}))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local event = self:GetCurrentEvent()
                if event then
                    local time = UtilsForEvent:GetEventInfo(event)
                    if time > 2 then
                        NetManager:getFreeSpeedUpPromise(self:GetEventTypeByBuilding(), event.id)
                    end
                end
            end
        end):align(display.CENTER, display.cx+194, display.top - 335):addTo(self.acc_layer)
    local building = self.building
    local event = User:GetBuildingEventByLocation(self:GetCurrentLocation())
    if event then
        local time = UtilsForEvent:GetEventInfo(event)
        if DataUtils:getFreeSpeedUpLimitTime() >= time then
            self.acc_layer.acc_button:setButtonEnabled(true)
        end
    else
        self.acc_layer.acc_button:setButtonEnabled(false)
    end

end

function CommonUpgradeUI:SetAccTipLabel()
    --TODO 设置对应的提示 ，现在是临时的
    self.acc_tip_label:setString(_("小于5分钟时，可使用免费加速.激活VIP X后，小于5分钟时可使用免费加速"))
end
function CommonUpgradeUI:GetEventTypeByBuilding()
    return City:IsFunctionBuilding(self.building) and "buildingEvents" or "houseEvents"
end
function CommonUpgradeUI:CreateAccButtons()
    -- 8个加速按钮单独放置在一个layer上方便处理事件
    self.acc_button_layer = WidgetAccelerateGroup.new(self:GetEventTypeByBuilding(),self.building:UniqueUpgradingKey()):addTo(self.acc_layer):align(display.BOTTOM_CENTER,window.cx,window.bottom_top+115)
    self:visibleChildLayers()
end

-- 设置各个layers显示状态
function CommonUpgradeUI:visibleChildLayers()
    local isupgrading = self:GetCurrentEvent() ~= nil
    if self.acc_button_layer then
        self.acc_button_layer:setVisible(isupgrading)
    end
    if self.upgrade_layer then
        self.upgrade_layer:setVisible(not isupgrading)
    end
    if self.acc_layer then
        self.acc_layer:setVisible(isupgrading)
    end
end


function CommonUpgradeUI:ResetAccButtons()
    for k,v in pairs(self.time_button_tbale) do
        v:setVisible(true)
    end
    for k,v in pairs(self.acc_button_table) do
        v:setVisible(false)
    end
end

function CommonUpgradeUI:PopNotSatisfyDialog(listener,can_not_update_type)
    local dialog = UIKit:showMessageDialog()
    local required_gems =self.building:getUpgradeRequiredGems()
    local owen_gem = City:GetUser():GetGemValue()
    if can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.RESOURCE_NOT_ENOUGH then
        dialog:SetTitle(_("补充资源"))
        dialog:SetPopMessage(_("您当前没有足够的资源,是否花费魔法石立即补充"))
        dialog:CreateOKButtonWithPrice(
            {
                listener = function()
                    if owen_gem<required_gems then
                        UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                            {
                                listener = function ()
                                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                end,
                                btn_name= _("前往商店")
                            })
                    else
                        listener()
                    end
                end,
                btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                price = required_gems
            }
        ):CreateCancelButton()
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_NOT_ENOUGH then
        if User.basicInfo.buildQueue == 2 then
            dialog:CreateOKButtonWithPrice(
                {
                    listener = function()
                        if owen_gem<required_gems then
                            UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                                {
                                    listener = function ()
                                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    end,
                                    btn_name= _("前往商店")
                                })
                        else
                            listener()
                        end
                    end,
                    btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                    price = required_gems,
                }
            ):CreateCancelButton()
        else
            dialog:CreateOKButtonWithPrice(
                {
                    listener = function()
                        if owen_gem<required_gems then
                            UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                                {
                                    listener = function ()
                                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    end,
                                    btn_name= _("前往商店")
                                })
                        else
                            listener()
                        end
                    end,
                    price = required_gems,
                    btn_name = _("立即完成")
                }
            ):CreateCancelButton({
                listener = function()
                    UIKit:newGameUI("GameUIActivityRewardNew",4):AddToCurrentScene(true)
                end,
                btn_name = {_("开启"),_("第2队列")},
                btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"},
                label_size = 20
            })
        end
        dialog:SetTitle(_("立即开始"))
        dialog:SetPopMessage(_("您当前没有空闲的建筑,是否花费魔法石立即完成上一个队列"))
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_AND_RESOURCE_NOT_ENOUGH then
        if User.basicInfo.buildQueue == 2 then
            dialog:CreateOKButtonWithPrice(
                {
                    listener = function()
                        if owen_gem<required_gems then
                            UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                                {
                                    listener = function ()
                                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    end,
                                    btn_name= _("前往商店")
                                })
                        else
                            listener()
                        end
                    end,
                    btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                    price = required_gems
                }
            ):CreateCancelButton()
        else
            dialog:CreateOKButtonWithPrice(
                {
                    listener = function()
                        if owen_gem<required_gems then
                            UIKit:showMessageDialog(_("提示"),_("金龙币不足")):CreateOKButton(
                                {
                                    listener = function ()
                                        UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                    end,
                                    btn_name= _("前往商店")
                                })
                        else
                            listener()
                        end
                    end,
                    price = required_gems,
                    btn_name = _("立即完成")
                }
            ):CreateCancelButton({
                listener = function()
                    UIKit:newGameUI("GameUIActivityRewardNew",4):AddToCurrentScene(true)
                end,
                btn_name = {_("开启"),_("第2队列")},
                btn_images = {normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"},
                label_size = 20
            })
        end
        dialog:SetTitle(_("立即开始"))
        dialog:SetPopMessage(can_not_update_type)
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.PRE_CONDITION then
        local jump_building = self.building:GetPreConditionBuilding()
        if tolua.type(jump_building) == "string" then
            dialog:SetTitle("提示")
                :SetPopMessage(string.format(_("请首先建造%s"),Localize.building_name[jump_building]))
                :CreateOKButton()
        else
            dialog:CreateOKButton(
                {
                    listener = handler(self,self.GotoPreconditionBuilding),
                    btn_name= _("前往")
                }
            )
            dialog:SetTitle(_("提示"))
            dialog:SetPopMessage(self.building:GetPreConditionDesc())
        end
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.FREE_CITIZEN_ERROR then
        local city =  self.building:BelongCity()
        local preName = "dwelling"
        local highest_level_building = city:GetLowestestBuildingByType(preName)

        local jump_building = highest_level_building or city:GetRuinsNotBeenOccupied()[1] or preName

        dialog:SetTitle("提示")
            :SetPopMessage(can_not_update_type)
        if tolua.type(jump_building) ~= "string" then
            dialog:CreateOKButton(
                {
                    listener = function ( ... )
                        local current_scene = display.getRunningScene()
                        local building_sprite = current_scene:GetSceneLayer():FindBuildingSpriteByBuilding(jump_building, city)
                        self:getParent():getParent():LeftButtonClicked()
                        local x,y = jump_building:GetMidLogicPosition()
                        current_scene:GotoLogicPoint(x,y,40):next(function()
                            if current_scene.AddIndicateForBuilding then
                                current_scene:AddIndicateForBuilding(building_sprite)
                            end
                        end)
                    end,
                    btn_name= _("前往")
                }
            )
        end
    elseif can_not_update_type == UpgradeBuilding.NOT_ABLE_TO_UPGRADE.GEM_NOT_ENOUGH then
        dialog:SetTitle(_("提示"))
        dialog:SetPopMessage(can_not_update_type)
        dialog:CreateOKButton(
            {
                listener = function ()
                    UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                    self:getParent():getParent():LeftButtonClicked()
                end,
                btn_name= _("前往商店")
            }
        )
    else
        dialog:SetTitle(_("提示"))
        dialog:SetPopMessage(can_not_update_type)
    end
end

return CommonUpgradeUI




























