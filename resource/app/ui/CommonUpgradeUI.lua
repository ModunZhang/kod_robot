local SmallDialogUI = import(".SmallDialogUI")
local UIListView = import(".UIListView")
local Localize = import("..utils.Localize")
local window = import("..utils.window")
local UpgradeBuilding = import("..entity.UpgradeBuilding")
local MaterialManager = import("..entity.MaterialManager")
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
    self.city:GetResourceManager():AddObserver(self)

    self:AddUpgradeListener()
end

function CommonUpgradeUI:onExit()
    self.city:GetResourceManager():RemoveObserver(self)
    self:RemoveUpgradeListener()
end

function CommonUpgradeUI:OnResourceChanged(resource_manager)
    if self.building:GetNextLevel() == self.building:GetLevel() then
        return
    end
    self.upgrade_layer:isVisible()
    if self.upgrade_layer:isVisible() then
        self:SetUpgradeRequirementListview()
    end
end

function CommonUpgradeUI:AddUpgradeListener()

    self.building:AddUpgradeListener(self)
end

function CommonUpgradeUI:RemoveUpgradeListener()
    self.building:RemoveUpgradeListener(self)
end
function CommonUpgradeUI:OnBuildingUpgradingBegin( buidling, current_time )
    local pro = self.acc_layer.ProgressTimer
    pro:setPercentage(self.building:GetUpgradingPercentByCurrentTime(current_time))
    self.acc_layer.upgrade_time_label:setString(GameUtils:formatTimeStyle1(self.building:GetUpgradingLeftTimeByCurrentTime(current_time)))
    self:visibleChildLayers()
end
function CommonUpgradeUI:OnBuildingUpgradeFinished( buidling )
    self:visibleChildLayers()
    self:SetBuildingLevel()
    self:SetUpgradeNowNeedGems()
    self:SetBuildingIntroduces()
    self:SetUpgradeTime()
    self:SetUpgradeEfficiency()
    self:ReloadBuildingImage()
    if self.building:GetNextLevel() == self.building:GetLevel() then
        self.upgrade_layer:setVisible(false)
    end
end

function CommonUpgradeUI:OnBuildingUpgrading( buidling, current_time )
    local pro = self.acc_layer.ProgressTimer
    pro:setPercentage(self.building:GetUpgradingPercentByCurrentTime(current_time))
    self.acc_layer.upgrade_time_label:setString(GameUtils:formatTimeStyle1(self.building:GetUpgradingLeftTimeByCurrentTime(current_time)))
    if not self.acc_layer.acc_button:isButtonEnabled() and
        self.building:IsAbleToFreeSpeedUpByTime(current_time) then
        self.acc_layer.acc_button:setButtonEnabled(true)
    end
end

function CommonUpgradeUI:InitCommonPart()
    -- building level
    local level_bg = display.newSprite("upgrade_level_bg.png", display.cx+80, display.top-125):addTo(self)
    self.builging_level = UIKit:ttfLabel({
        font = UIKit:getFontFilePath(),
        size = 26,
        color = 0xffedae,
        bold = true
    }):align(display.LEFT_CENTER, 20, level_bg:getContentSize().height/2)
        :addTo(level_bg)
    -- 建筑功能介绍
    -- 建筑图片 放置区域左右边框
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, display.cx-250, display.top-175)
        :addTo(self):setFlippedX(true)
    cc.ui.UIImage.new("building_frame_36x136.png"):align(display.CENTER, display.cx-145, display.top-175)
        :addTo(self)
    self:ReloadBuildingImage()
    self:InitBuildingIntroduces()
    self:InitNextLevelEfficiency()
    self:SetBuildingLevel()
end
function CommonUpgradeUI:ReloadBuildingImage()
    if self.building_image then
        self.building_image:removeFromParent()
    end
    local config = SpriteConfig[self.building:GetType()]:GetConfigByLevel(self.building:GetLevel())
    local configs = SpriteConfig[self.building:GetType()]:GetAnimationConfigsByLevel(self.building:GetLevel())
    self.building_image = display.newSprite(config.png, 0, 0)
    :addTo(self):pos(display.cx-196, display.top-158)
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
        self.next_level:setString(_("等级已满 "))
    else
        self.next_level:setString(_("等级 ")..self.building:GetNextLevel())
    end
end

function CommonUpgradeUI:InitBuildingIntroduces()
    self.building_introduces = UIKit:ttfLabel({
        size = 18,
        dimensions = cc.size(380, 90),
        color = 0x615b44
    }):align(display.LEFT_CENTER,display.cx-110, display.top-190):addTo(self)
    self:SetBuildingIntroduces()
end
function CommonUpgradeUI:SetBuildingIntroduces()
    local bd = Localize.building_description
    self.building_introduces:setString(bd[self.building:GetType()])
end


function CommonUpgradeUI:InitNextLevelEfficiency()
    -- 下一级 框
    local bg  = display.newSprite("upgrade_next_level_bg.png", window.left+114, window.top-310):addTo(self)
    local bg_size = bg:getContentSize()
    self.next_level = UIKit:ttfLabel({
        size = 20,
        color = 0x403c2f
    }):align(display.CENTER,bg_size.width/2,bg_size.height/2):addTo(bg)

    local efficiency_bg = display.newSprite("back_ground_398x97.png", window.cx+74, window.top-310):addTo(self)
    local efficiency_bg_size = efficiency_bg:getContentSize()
    self.efficiency = UIKit:ttfLabel({
        size = 20,
        dimensions = cc.size(370,0),
        valign = cc.ui.UILabel.TEXT_VALIGN_CENTER,
        align = cc.ui.UILabel.TEXT_ALIGN_CENTER,
        color = 0x403c2f
    }):addTo(efficiency_bg):align(display.LEFT_CENTER)
    self.efficiency:pos(14,efficiency_bg_size.height/2)
    self:SetUpgradeEfficiency()
end

function CommonUpgradeUI:SetUpgradeEfficiency()
    local bd = Localize.building_description
    local building = self.building
    local efficiency = ""
    if self.building:GetType()=="keep" then
        local unlock_point = building:GetNextLevelUnlockPoint()-building:GetUnlockPoint()
        if unlock_point>0 then
            efficiency = efficiency..string.format("%s+%d,",bd.unlock,unlock_point)
        end
        local be_helped_count = building:GetNextLevelBeHelpedCount()-building:GetBeHelpedCount()
        if be_helped_count>0 then
            efficiency = efficiency.. string.format("%s+%d,",bd.beHelpCount,be_helped_count)
        end
    elseif self.building:GetType()=="dragonEyrie" then
        local additon = building:GetNextLevelHPRecoveryPerHour()-building:GetHPRecoveryPerHourWithoutBuff()
        if additon>0 then
            efficiency = efficiency .. string.format("%s+%d,",bd.vitalityRecoveryPerHour,additon)
        end
    elseif self.building:GetType()=="watchTower" then
        efficiency = string.format("%s,",bd["watchTower_"..self.building:GetLevel()])
    elseif self.building:GetType()=="warehouse" then
        local additon = building:GetResourceNextLevelValueLimit()-building:GetResourceValueLimit()
        if additon>0 then
            efficiency = string.format("%s%d,",bd.warehouse_max,additon)
        end
    elseif self.building:GetType()=="toolShop" then
        local additon = building:GetNextLevelProduction()-building:GetProduction()
        if additon>0 then
            efficiency = string.format("%s+%d%s,",bd.poduction,additon,bd.poduction_1)
        end
    elseif self.building:GetType()=="materialDepot" then
        local additon = building:GetNextLevelMaxMaterial()-building:GetMaxMaterial()
        if additon>0 then
            efficiency = string.format("%s+%d,",bd.maxMaterial,additon)
        end
    elseif self.building:GetType()=="barracks" then
        local additon = building:GetNextLevelMaxRecruitSoldierCount()-building:GetMaxRecruitSoldierCount()
        if additon>0 then
            efficiency = string.format("%s+%d,",bd.maxRecruit,additon)
        end
    elseif self.building:GetType()=="blackSmith" then
        local additon = (building:GetNextLevelEfficiency()-building:GetEfficiency())*100
        if additon>0 then
            efficiency = string.format("%s+%.1f%%,",bd.blackSmith_efficiency,additon)
        end
    elseif self.building:GetType()=="foundry" then
        local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        efficiency = ""
        if house_add>0 then
            efficiency = string.format("%s+%d," ,bd.foundry_miner,house_add)
        end
        local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        if addtion>0 then
            efficiency = efficiency..string.format("%s+%.1f%%,",bd.foundry_protection,addtion)
        end
    elseif self.building:GetType()=="lumbermill" then
        local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        efficiency = ""
        if house_add>0 then
            efficiency = string.format("%s+%d," ,bd.lumbermill_woodcutter,house_add)
        end
        local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        if addtion>0 then
            efficiency = efficiency..string.format("%s+%.1f%%,",bd.lumbermill_protection,addtion)
        end
    elseif self.building:GetType()=="mill" then
        local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        efficiency = ""
        if house_add>0 then
            efficiency = string.format("%s+%d," ,bd.mill_farmer,house_add)
        end
        local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        if addtion>0 then
            efficiency = efficiency..string.format("%s+%.1f%%,",bd.mill_protection,addtion)
        end
    elseif self.building:GetType()=="stoneMason" then
        local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        efficiency = ""
        if house_add>0 then
            efficiency = string.format("%s+%d," ,bd.stoneMason_quarrier,house_add)
        end
        local addtion = (building:GetNextLevelProtection()-building:GetProtection())*100
        if addtion>0 then
            efficiency = efficiency..string.format("%s+%.1f%%,",bd.stoneMason_protection,addtion)
        end
    elseif self.building:GetType()=="hospital" then
        local addtion = building:GetNextLevelMaxCasualty()-building:GetMaxCasualty()
        if addtion>0 then
            efficiency = string.format("%s+%d,",bd.maxCasualty,addtion)
        end
    elseif self.building:GetType()=="townHall" then
        local house_add = building:GetNextLevelMaxHouseNum()-building:GetMaxHouseNum()
        efficiency = ""
        if house_add>0 then
            efficiency = string.format("%s+%d," ,bd.townHall_dwelling,house_add)
        end
    elseif self.building:GetType()=="dwelling" then
        local addtion = building:GetNextLevelCitizen()-building:GetProductionLimit()
        if addtion>0 then
            efficiency = string.format("%s+%d,",bd.dwelling_citizen,addtion)
        end
    elseif self.building:GetType()=="woodcutter" then
        local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        if addtion>0 then
            efficiency = string.format("%s+%d,",bd.woodcutter_poduction,addtion)
        end
    elseif self.building:GetType()=="farmer" then
        local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        if addtion>0 then
            efficiency = string.format("%s+%d,",bd.farmer_poduction,addtion)
        end
    elseif self.building:GetType()=="quarrier" then
        local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        if addtion>0 then
            efficiency = string.format("%s+%d,",bd.quarrier_poduction,addtion)
        end
    elseif self.building:GetType()=="miner" then
        local addtion = building:GetNextLevelProductionPerHour()-building:GetProductionPerHour()
        if addtion>0 then
            efficiency = string.format("%s+%d,",bd.miner_poduction,addtion)
        end
    else
        assert(false,"本地化丢失")
    end
    -- 增加power,每个建筑都有的属性
    efficiency = efficiency ..string.format("%s+%d",bd.power,building:GetNextLevelPower()-building:GetPower())
    self.efficiency:setString(efficiency)
end

function CommonUpgradeUI:InitUpgradePart()
    -- 升级页
    if self.building:GetNextLevel() == self.building:GetLevel() then
        return
    end
    self.upgrade_layer = display.newLayer()
    self.upgrade_layer:setContentSize(cc.size(display.width,575))
    self:addChild(self.upgrade_layer)
    -- upgrade now button
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即升级")},
            listener = function ()
                local upgrade_listener = function()
                    if self.building:GetType()=="tower" then
                        NetManager:getInstantUpgradeTowerPromise()
                    elseif self.building:GetType()=="wall" then
                        NetManager:getInstantUpgradeWallByLocationPromise()
                    else
                        if City:IsFunctionBuilding(self.building) then

                            local location_id = City:GetLocationIdByBuilding(self.building)
                            NetManager:getInstantUpgradeBuildingByLocationPromise(location_id)
                        else
                            local tile = City:GetTileWhichBuildingBelongs(self.building)
                            local house_location = tile:GetBuildingLocation(self.building)
                            NetManager:getInstantUpgradeHouseByLocationPromise(tile.location_id, house_location)
                        end
                    end
                end

                local can_not_update_type = self.building:IsAbleToUpgrade(true)
                if can_not_update_type then
                    self:PopNotSatisfyDialog(upgrade_listener,can_not_update_type)
                else
                    upgrade_listener()
                end
            end,
        }
    ):pos(display.cx-150, display.top-410)
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
                            local location_id = City:GetLocationIdByBuilding(self.building)
                            NetManager:getUpgradeBuildingByLocationPromise(location_id)
                        else
                            local tile = City:GetTileWhichBuildingBelongs(self.building)
                            local house_location = tile:GetBuildingLocation(self.building)
                            NetManager:getUpgradeHouseByLocationPromise(tile.location_id, house_location)
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
    ):pos(display.cx+180, display.top-410)
        :addTo(self.upgrade_layer)

    self.upgrade_btn = btn_bg.button

    -- 立即升级所需金龙币
    display.newSprite("gem_icon_62x61.png", display.cx - 260, display.top-470):addTo(self.upgrade_layer):setScale(0.5)
    self.upgrade_now_need_gems_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,display.cx - 240,display.top-474):addTo(self.upgrade_layer)
    self:SetUpgradeNowNeedGems()
    --升级所需时间
    display.newSprite("hourglass_30x38.png", display.cx+100, display.top-470):addTo(self.upgrade_layer):setScale(0.6)
    self.upgrade_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER,display.cx+125,display.top-460):addTo(self.upgrade_layer)

    -- 科技减少升级时间
    self.buff_reduce_time = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = "(-00:20:00)",
        font = UIKit:getFontFilePath(),
        size = 18,
        color = UIKit:hex2c3b(0x068329)
    }):align(display.LEFT_CENTER,display.cx+120,display.top-480):addTo(self.upgrade_layer)

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
    local wood = city.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = city.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = city.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local population = city.resource_manager:GetPopulationResource():GetNoneAllocatedByTime(app.timer:GetServerTime())

    local materials = city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)
    local building = self.building
    local pre_condition = building:IsBuildingUpgradeLegal()
    local requirements = {
        {
            resource_type = _("前置条件"),
            isVisible = building:GetLevel()>5,
            isSatisfy = not pre_condition,canNotBuy=true,
            icon="hammer_31x33.png",
            description = building:GetPreConditionDesc(),jump_call = handler(self,self.GotoPreconditionBuilding)
        },
        {
            resource_type = "building_queue",
            isVisible = #city:GetUpgradingBuildings()>=city:BuildQueueCounts(),
            isSatisfy = #city:GetUpgradingBuildings()<city:BuildQueueCounts(),
            icon="hammer_31x33.png",
            description=_("建造队列已满")..(city:BuildQueueCounts()-#city:GetUpgradingBuildings()).."/"..1
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
            isSatisfy = population>=building:GetLevelUpCitizen() ,
            icon="res_citizen_88x82.png",
            description=population.."/"..building:GetLevelUpCitizen()
        },

        {
            resource_type = _("建筑蓝图"),
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
            height = 298,
            contents = requirements,
        }):addTo(self.upgrade_layer):pos(display.cx-272, display.top-846)
    end
    self.requirement_listview:RefreshListView(requirements)
end

function CommonUpgradeUI:InitAccelerationPart()
    if self.building:GetNextLevel() == self.building:GetLevel() then
        return
    end
    self.acc_layer = display.newLayer()
    self.acc_layer:setContentSize(cc.size(display.width,575))
    self:addChild(self.acc_layer)

    -- 正在升级文本说明
    cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        text = string.format(_("正在升级 %s 到等级 %d"),Localize.getBuildingLocalizedKeyByBuildingType(self.building:GetType()),self.building:GetLevel()+1),
        font = UIKit:getFontFilePath(),
        size = 22,
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER, display.cx - 260, display.top - 410)
        :addTo(self.acc_layer)
    -- 升级倒数时间进度条
    --进度条
    local bar = display.newSprite("progress_bar_364x40_1.png"):addTo(self.acc_layer):pos(display.cx-78, display.top - 450)
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
    if self.building:IsUpgrading() then
        pro:setPercentage(self.building:GetUpgradingPercentByCurrentTime(app.timer:GetServerTime()))
        self.acc_layer.upgrade_time_label:setString(GameUtils:formatTimeStyle1(self.building:GetUpgradingLeftTimeByCurrentTime(app.timer:GetServerTime())))
    end

    -- 进度条头图标
    display.newSprite("back_ground_43x43.png", display.cx - 250, display.top - 450):addTo(self.acc_layer)
    display.newSprite("hourglass_30x38.png", display.cx - 250, display.top - 450):addTo(self.acc_layer):setScale(0.8)
    -- 免费加速按钮
    self:CreateFreeSpeedUpBuildingUpgradeButton()
    -- 可免费加速提示
    -- 背景框
    WidgetUIBackGround.new({width = 546,height=90},WidgetUIBackGround.STYLE_TYPE.STYLE_3):align(display.CENTER,  display.cx, display.top - 540):addTo(self.acc_layer)
    self.acc_tip_label = cc.ui.UILabel.new({
        UILabelType = cc.ui.UILabel.LABEL_TYPE_TTF,
        font = UIKit:getFontFilePath(),
        size = 20,
        dimensions = cc.size(530, 80),
        color = UIKit:hex2c3b(0x403c2f)
    }):align(display.LEFT_CENTER, display.cx - 270, display.top - 540)
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
        :setButtonLabel(ui.newTTFLabel({
            text = _("免费加速"),
            size = 24,
            color = UIKit:hex2c3b(0xffedae)
        }))
        :onButtonClicked(function(event)
            if event.name == "CLICKED_EVENT" then
                local eventType = self.building:EventType()
                NetManager:getFreeSpeedUpPromise(eventType,self.building:UniqueUpgradingKey())
            end
        end):align(display.CENTER, display.cx+194, display.top - 435):addTo(self.acc_layer)
    local building = self.building
    if building:IsUpgrading() and building:IsAbleToFreeSpeedUpByTime(app.timer:GetServerTime()) then
        self.acc_layer.acc_button:setButtonEnabled(true)
    else
        self.acc_layer.acc_button:setButtonEnabled(false)
    end

end

function CommonUpgradeUI:SetAccTipLabel()
    --TODO 设置对应的提示 ，现在是临时的
    self.acc_tip_label:setString(_("小于5分钟时，可使用免费加速.激活VIP X后，小于5分钟时可使用免费加速"))
end
function CommonUpgradeUI:GetEventTypeByBuilding()
    return self.building:EventType()
end
function CommonUpgradeUI:CreateAccButtons()
    -- 8个加速按钮单独放置在一个layer上方便处理事件
    self.acc_button_layer = WidgetAccelerateGroup.new(self:GetEventTypeByBuilding(),self.building:UniqueUpgradingKey()):addTo(self.acc_layer):align(display.BOTTOM_CENTER,window.cx,window.bottom_top+10)
    self:visibleChildLayers()
end

-- 设置各个layers显示状态
function CommonUpgradeUI:visibleChildLayers()
    if self.acc_button_layer then
        self.acc_button_layer:setVisible(self.building:IsUpgrading())
    end
    if self.upgrade_layer then
        self.upgrade_layer:setVisible(not self.building:IsUpgrading())
    end
    if self.acc_layer then
        self.acc_layer:setVisible(self.building:IsUpgrading())
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
    if can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.RESOURCE_NOT_ENOUGH then
        local required_gems =self.building:getUpgradeRequiredGems()
        local owen_gem = City:GetUser():GetGemResource():GetValue()
        dialog:SetTitle(_("补充资源"))
        dialog:SetPopMessage(_("您当前没有足够的资源,是否花费魔法石立即补充"))

        if owen_gem<required_gems then
            dialog:CreateNeeds({value = required_gems,color =0x7e0000})
            dialog:CreateOKButton(
                {
                    listener = function()
                        UIKit:newGameUI('GameUIShop', City):AddToCurrentScene(true)
                        self:getParent():getParent():LeftButtonClicked()
                    end
                }
            )
        else
            dialog:CreateNeeds({value = required_gems})
            dialog:CreateOKButton(
                {
                    listener = function()
                        listener()
                    end
                }
            )
        end
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_NOT_ENOUGH then
        local required_gems = self.building:getUpgradeRequiredGems()
        dialog:CreateOKButton(
            {
                listener = function()
                    listener()
                end
            }
        )
        dialog:SetTitle(_("立即开始"))
        dialog:SetPopMessage(_("您当前没有空闲的建筑,是否花费魔法石立即完成上一个队列"))
        dialog:CreateNeeds({value = required_gems})
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.BUILDINGLIST_AND_RESOURCE_NOT_ENOUGH then
        local required_gems = self.building:getUpgradeRequiredGems()
        dialog:CreateOKButton(
            {
                listener = function(sender,type)
                    listener()
                end
            }
        )
        dialog:SetTitle(_("立即开始"))
        dialog:SetPopMessage(can_not_update_type)
        dialog:CreateNeeds({value = required_gems})
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
                        current_scene:GotoLogicPoint(jump_building:GetMidLogicPosition())
                        if current_scene.AddIndicateForBuilding then
                            current_scene:AddIndicateForBuilding(building_sprite)
                        end
                    end,
                    btn_name= _("前往")
                }
            )
        end
    elseif can_not_update_type==UpgradeBuilding.NOT_ABLE_TO_UPGRADE.GEM_NOT_ENOUGH then
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





























