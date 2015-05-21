--
-- Author: Danny He
-- Date: 2014-12-17 19:30:23
--
local GameUIUpgradeTechnology = UIKit:createUIClass("GameUIUpgradeTechnology","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")
local HEIGHT = 694
local window = import("..utils.window")
local MaterialManager = import("..entity.MaterialManager")

function GameUIUpgradeTechnology:ctor(productionTechnology)
    self.productionTechnology = productionTechnology
    GameUIUpgradeTechnology.super.ctor(self)
end

function GameUIUpgradeTechnology:GetProductionTechnology()
    return self.productionTechnology
end

function GameUIUpgradeTechnology:onEnter()
    GameUIUpgradeTechnology.super.onEnter(self)
    if self:CheckIsMeUpgrade() then
        HEIGHT = 550
    else
        if self:CheckMeIsReachLimitLevel() then
            HEIGHT = 200
        else
            HEIGHT = 694
        end
    end
    self:BuildUI()
    City:AddListenOnType(self,City.LISTEN_TYPE.PRODUCTION_DATA_CHANGED)
    self:RefreshButtonState()
end

function GameUIUpgradeTechnology:OnMoveOutStage()
    GameUIUpgradeTechnology.super.OnMoveOutStage(self)
    City:RemoveListenerOnType(self,City.LISTEN_TYPE.PRODUCTION_DATA_CHANGED)
end

function GameUIUpgradeTechnology:OnProductionTechsDataChanged(changed_map)
    for _,tech in ipairs(changed_map.edited or {}) do
        if self:GetProductionTechnology():Index() == tech:Index() then
            if self:CheckMeIsReachLimitLevel() then
                self:LeftButtonClicked()
            else
                self:RefreshUI()
            end
        end
    end
end

function GameUIUpgradeTechnology:GetTechLevelStr()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        return self:GetProductionTechnology():GetLocalizedName() .. " " .. _("等级") .. " " .. self:GetProductionTechnology():GetNextLevel()
    end
    return self:GetProductionTechnology():GetLocalizedName() .. " " .. _("等级") .. " " .. self:GetProductionTechnology():Level()
end

function GameUIUpgradeTechnology:GetResourceCost()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        return self:GetProductionTechnology():GetNextLevelUpCost()
    end
    return self:GetProductionTechnology():GetLevelUpCost()
end

function GameUIUpgradeTechnology:GetLevelUpBuffTimeStr()
    local buildTime = 0
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        buildTime = self:GetProductionTechnology():GetNextLevelUpCost().buildTime
    end
    buildTime = self:GetProductionTechnology():GetLevelUpCost().buildTime
    return   string.format("(-%s)",GameUtils:formatTimeStyle1(DataUtils:getTechnilogyUpgradeBuffTime(buildTime)))
end

function GameUIUpgradeTechnology:GetLevelUpTimeStr()

    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        return GameUtils:formatTimeStyle1(self:GetProductionTechnology():GetNextLevelUpCost().buildTime)
    end
    return GameUtils:formatTimeStyle1(self:GetProductionTechnology():GetLevelUpCost().buildTime)
end

function GameUIUpgradeTechnology:GetBuffEffectStr()
    return self:GetProductionTechnology():GetBuffEffectVal() * 100  .. "%"
end

function GameUIUpgradeTechnology:GetPowerStr()
    return self:GetProductionTechnology():GetCurrentLevelPower()
end

function GameUIUpgradeTechnology:GetNextLevelBuffEffectStr()
    return self:GetProductionTechnology():GetNextLevelBuffEffectVal() * 100  .. "%"
end

function GameUIUpgradeTechnology:GetNextLevelPower()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        if self:GetProductionTechnology():GetNextLevelPower() > 0 then
            return  self:GetProductionTechnology():GetNextLevelPower() 
        else
            return 0
        end
    end
    return self:GetProductionTechnology():GetNextLevelPower() 
end

function GameUIUpgradeTechnology:RefreshUI()
    local tech = self:GetProductionTechnology()
    self.lv_label:setString(self:GetTechLevelStr())
    self.current_effect_val_label:setString(self:GetBuffEffectStr())
    self.current_power_val_label:setString(self:GetPowerStr())
    if not tech:IsReachLimitLevel() then
        self.upgrade_info_icon:show()
        self.next_effect_val_label:setString(self:GetNextLevelBuffEffectStr())
        self.upgrade_power_icon:show()
        self.next_power_val_label:setString(self:GetNextLevelPower())
        self.time_label:setString(self:GetLevelUpTimeStr())
        self.need_gems_label:setString(self:GetUpgradeNowGems())
        self.buff_time_label:setString(self:GetLevelUpBuffTimeStr())
        self.need_gems_icon:show()
        self.time_icon:show()
        self.upgrade_button:show()
        self.upgradeNowButton:show()
        self:RefreshRequirementList()
    else
        self.time_label:hide()
        self.need_gems_label:hide()
        self.next_effect_val_label:hide()
        self.upgrade_info_icon:hide()
        self.upgrade_power_icon:hide()
        self.next_power_val_label:hide()
        self.buff_time_label:hide()
        self.need_gems_icon:hide()
        self.time_icon:hide()
        self.upgrade_button:hide()
        self.upgradeNowButton:hide()
        if self.listView then
            self.listView:hide()
        end
        local x = self.line_1:getPositionX() + self.line_1:getContentSize().width
        self.current_effect_val_label:setPositionX(x)
        self.current_power_val_label:setPositionX(x)
    end
end

function GameUIUpgradeTechnology:GetTechIcon()
    local bg = display.newSprite("technology_bg_116x116.png"):scale(0.95)
    local icon_image = self:GetProductionTechnology():GetImageName()
    bg.enable_icon = display.newSprite(icon_image):addTo(bg):pos(58,58):scale(0.85)
    bg.unable_icon = display.newFilteredSprite(icon_image,"GRAY", {0.2,0.5,0.1,0.1}):addTo(bg):pos(58,58):scale(0.85)
    bg.lock_icon = display.newSprite("technology_lock_40x54.png"):addTo(bg):pos(58,58)
    bg.changeState = function(enable)
        if enable then
            bg.enable_icon:show()
            bg.unable_icon:hide()
            bg.lock_icon:hide()
        else
            bg.enable_icon:hide()
            bg.unable_icon:show()
            bg.lock_icon:show()
        end
    end
    bg.changeState(self:GetProductionTechnology():Enable())
    return bg
end

function GameUIUpgradeTechnology:BuildUI()
    local y = window.top_bottom - 50
    if HEIGHT == 200 then
        y = window.top_bottom - 200
    end
    local bg_node =  WidgetUIBackGround.new({height = HEIGHT,isFrame = "no"}):align(display.TOP_CENTER, window.cx, y)
    self:addTouchAbleChild(bg_node)
    local title_bar = display.newSprite("title_blue_600x56.png"):align(display.BOTTOM_CENTER,304,HEIGHT - 15):addTo(bg_node)
    UIKit:closeButton():align(display.RIGHT_BOTTOM,600, 0):addTo(title_bar):onButtonClicked(function()
        self:LeftButtonClicked()
    end)
    UIKit:ttfLabel({text = _("科技研发"),
        size = 22,
        color = 0xffedae
    }):align(display.CENTER,300, 28):addTo(title_bar)
    local box = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_TOP, 20, title_bar:getPositionY() - 20):addTo(bg_node)
    self.tech_bg = self:GetTechIcon():pos(63,63):addTo(box):scale(0.95)

    local title = display.newScale9Sprite("alliance_event_type_darkblue_222x30.png",0,0, cc.size(438,30), cc.rect(7,7,190,16))
        :align(display.LEFT_TOP,box:getPositionX()+box:getContentSize().width + 10, box:getPositionY())
        :addTo(bg_node)
    self.lv_label = UIKit:ttfLabel({
        text = self:GetTechLevelStr(),
        size = 22,
        color= 0xffedae
    }):align(display.LEFT_CENTER, 10, 15):addTo(title)
    local line_2 = display.newScale9Sprite("dividing_line_594x2.png"):size(422,1)
        :align(display.LEFT_BOTTOM,box:getPositionX()+box:getContentSize().width + 10, box:getPositionY()-box:getContentSize().height)
        :addTo(bg_node)
    local line_1 = display.newScale9Sprite("dividing_line_594x2.png"):size(422,1)
        :align(display.LEFT_BOTTOM,line_2:getPositionX(), line_2:getPositionY() + 40)
        :addTo(bg_node)
    self.line_1 = line_1
    local current_effect_desc = UIKit:ttfLabel({
        text = self:GetProductionTechnology():GetBuffLocalizedDesc(),
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_BOTTOM,line_1:getPositionX()+6, line_1:getPositionY() + 5):addTo(bg_node)
    local next_effect_val_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_BOTTOM,line_1:getPositionX()+ 422,current_effect_desc:getPositionY()):addTo(bg_node)
    self.next_effect_val_label = next_effect_val_label

    self.upgrade_info_icon = display.newSprite("teach_upgrade_icon_15x17.png"):align(display.RIGHT_BOTTOM, next_effect_val_label:getPositionX() - 70,
        next_effect_val_label:getPositionY() + 5):addTo(bg_node)

    local current_effect_val_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_BOTTOM,self.upgrade_info_icon:getPositionX() - 55, next_effect_val_label:getPositionY()):addTo(bg_node)
    self.current_effect_val_label = current_effect_val_label

    local current_power_desc = UIKit:ttfLabel({
        text = _("战斗力"),
        size = 20,
        color= 0x615b44
    }):addTo(bg_node):align(display.LEFT_BOTTOM,line_2:getPositionX()+6, line_2:getPositionY() + 5)

    local next_power_val_label = UIKit:ttfLabel({
        text = "123", 
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_BOTTOM,line_2:getPositionX()+ 422,current_power_desc:getPositionY()):addTo(bg_node)
    self.next_power_val_label = next_power_val_label
    self.upgrade_power_icon = display.newSprite("teach_upgrade_icon_15x17.png"):align(display.RIGHT_BOTTOM, next_power_val_label:getPositionX() - 70,
        next_power_val_label:getPositionY() + 5):addTo(bg_node)

    local current_power_val_label = UIKit:ttfLabel({
        text = "0",
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_BOTTOM,self.upgrade_power_icon:getPositionX() - 55, next_power_val_label:getPositionY()):addTo(bg_node)
    self.current_power_val_label = current_power_val_label
    local btn_now = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即研发")},
            listener = function ()
                self:OnUpgradNowButtonClicked()
            end,
        }):align(display.LEFT_TOP, 30, line_2:getPositionY() - 30):addTo(bg_node)
    self.upgradeNowButton = btn_now

    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams={text = _("研发")},
            listener = function ()
                self:OnUpgradButtonClicked()
            end,
        }
    ):align(display.RIGHT_TOP, line_2:getPositionX()+line_2:getContentSize().width, line_2:getPositionY() - 30)
        :addTo(bg_node)
    self.upgrade_button = btn_bg
    local gem = display.newSprite("gem_icon_62x61.png")
        :addTo(bg_node)
        :scale(0.5)
        :align(display.LEFT_TOP, btn_now:getPositionX(), btn_now:getPositionY() - 65 - 10)
    self.need_gems_icon = gem
    self.need_gems_label = UIKit:ttfLabel({
        text = "",
        size = 20,
        color= 0x403c2f
    }):align(display.LEFT_TOP,gem:getPositionX() + gem:getCascadeBoundingBox().width + 10, gem:getPositionY()):addTo(bg_node)


    --升级所需时间
    local time_icon = display.newSprite("hourglass_30x38.png")
        :addTo(bg_node)
        :scale(0.6)
        :align(display.LEFT_TOP, btn_bg:getPositionX() - 185,btn_bg:getPositionY() - 65 - 10)
    self.time_icon = time_icon
    self.time_label = UIKit:ttfLabel({
        text = "",
        size = 18,
        color= 0x403c2f
    }):align(display.LEFT_TOP, time_icon:getPositionX()+time_icon:getCascadeBoundingBox().width + 10, time_icon:getPositionY()):addTo(bg_node)

    self.buff_time_label = UIKit:ttfLabel({
        text = "(-00:20:00)",
        size = 18,
        color= 0x068329
    }):align(display.LEFT_TOP,time_icon:getPositionX()+time_icon:getCascadeBoundingBox().width + 10,time_icon:getPositionY()-20):addTo(bg_node)
    if not self:GetProductionTechnology():IsReachLimitLevel() then
        local requirements = self:GetUpgradeRequirements()
        self.listView = WidgetRequirementListview.new({
            title = _("研发需求"),
            height = 270,
            contents = requirements,
        }):addTo(bg_node):pos(30,40)
    end

    self:RefreshUI()
    if self:CheckIsMeUpgrade() then
        self.upgradeNowButton:hide()
        self.upgrade_button:hide()
        self.need_gems_icon:hide()
        self.need_gems_label:hide()
        self.time_icon:hide()
        self.time_label:hide()
        self.buff_time_label:hide()
    end
end


function GameUIUpgradeTechnology:RefreshRequirementList()
    local requirements = self:GetUpgradeRequirements()
    self.listView:RefreshListView(requirements)
end

function GameUIUpgradeTechnology:GetUpgradeRequirements()
    local requirements = {}
    local current_tech = self:GetProductionTechnology()
    local unLockByTech = City:FindTechByIndex(current_tech:UnlockBy())
    local cost =  self:GetResourceCost()
    local coin = City.resource_manager:GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    table.insert(requirements,
        {
            resource_type = _("升级队列"),
            isVisible = true,
            isSatisfy = not City:HaveProductionTechEvent(),
            icon="hammer_33x40.png",
            description= City:HaveProductionTechEvent() and "0/1" or "1/1"
        })
    if unLockByTech:Index() ~= current_tech:Index() then
        table.insert(requirements,
            {
                resource_type = unLockByTech:GetLocalizedName(),
                isVisible = true,
                isSatisfy = unLockByTech:Level() >= current_tech:UnlockLevel(),
                icon= unLockByTech:GetImageName(),
                description= _("等级达到") .. current_tech:UnlockLevel(),
                canNotBuy = true,
            })
    end
     table.insert(requirements,
        {
            resource_type = _("学院等级"),
            isVisible = true,
            isSatisfy = current_tech:AcademyLevel() <= City:GetAcademyBuildingLevel(),
            icon="academy.png",
            description = _("等级达到") .. current_tech:AcademyLevel(),
            canNotBuy = true,
        })
    table.insert(requirements,
        {
            resource_type = _("银币"),
            isVisible = cost.coin >0,
            isSatisfy = coin >= cost.coin,
            icon="res_coin_81x68.png",
            description=  coin .."/".. cost.coin
        })
    table.insert(requirements,
        {
            resource_type = _("建筑蓝图"),
            isVisible = cost.blueprints>0,
            isSatisfy = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["blueprints"]>=cost.blueprints,
            icon="blueprints_112x112.png",
            description= City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["blueprints"] .."/"..  cost.blueprints
        })
    table.insert(requirements,
        {
            resource_type = _("建造工具"),
            isVisible = cost.tools>0,
            isSatisfy = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["tools"]>=cost.tools,
            icon="tools_112x112.png",
            description= City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["tools"] .."/".. cost.tools
        })
    table.insert(requirements,
        {
            resource_type = _("砖石瓦片"),
            isVisible = cost.tiles>0,
            isSatisfy = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["tiles"]>=cost.tiles,
            icon="tiles_112x112.png",
            description= City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["tiles"] .. "/" .. cost.tiles
        })
    table.insert(requirements,
        {
            resource_type = _("滑轮组"),
            isVisible = cost.pulley>0,
            isSatisfy = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["pulley"]>=cost.pulley,
            icon="pulley_112x112.png",
            description = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["pulley"] .. "/" .. cost.pulley
        })  
   
    -- table.sort( requirements, function(a,b)
    --     return not a.isSatisfy and b.isSatisfy
    -- end)
    return requirements
end

function GameUIUpgradeTechnology:OnUpgradNowButtonClicked()
    local canUpgrade,msg = self:CheckCanUpgradeNow()
    if canUpgrade then
        NetManager:getUpgradeProductionTechPromise(self:GetProductionTechnology():Name(),true)
    else
        UIKit:showMessageDialog(_("提示"),msg, function()end)
    end
end

function GameUIUpgradeTechnology:OnUpgradButtonClicked()
    local gems_cost,msg = self:CheckCanUpgradeActionReturnGems()
    if gems_cost < 0 then
        return
    elseif gems_cost == 0 then
        NetManager:getUpgradeProductionTechPromise(self:GetProductionTechnology():Name(),false):done(function()
            self:LeftButtonClicked()
            local acdemy = UIKit:GetUIInstance("GameUIAcademy")
            if acdemy then
                acdemy:LeftButtonClicked()
            end
        end)
    else
        UIKit:showMessageDialog(_("提示"),msg, function ()
            self:ForceUpgrade(gems_cost)
        end):CreateNeeds({value = gems_cost})
    end
end

function GameUIUpgradeTechnology:ForceUpgrade(gem_cost)
    if  User:GetGemResource():GetValue() < gem_cost then
        UIKit:showMessageDialog(_("提示"),_("金龙币不足"), function()
            UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
    else
        NetManager:getUpgradeProductionTechPromise(self:GetProductionTechnology():Name(),false):done(function(msg)
            self:LeftButtonClicked()
            local acdemy = UIKit:GetUIInstance("GameUIAcademy")
            if acdemy then
                acdemy:LeftButtonClicked()
            end
        end)
    end
end

--计算需要的资源
----------------------------------------------------------------------------------------------------------------

function GameUIUpgradeTechnology:GetNeedResourceAndMaterialsAndTime(tech)
    local cost = self:GetResourceCost()
    if not cost then return {},{},0 end
    return
        {
            coin = cost.coin
        },
        {
            blueprints = cost.blueprints,
            tools      = cost.tools,
            pulley      = cost.pulley,
        },
        cost.buildTime
end

function GameUIUpgradeTechnology:GetUpgradeNowGems()
    local resource,material,time = self:GetNeedResourceAndMaterialsAndTime()
    local resource_gems = DataUtils:buyResource(resource,{})
    local material_gems = DataUtils:buyMaterial(material,{})
    local time_gems = DataUtils:getGemByTimeInterval(time)
    return resource_gems + material_gems + time_gems
end

function GameUIUpgradeTechnology:CheckCanUpgradeNow()
    if not self:CheckUpgradeNowButtonState() then
        return false
    end
    return User:GetGemResource():GetValue() >= self:GetUpgradeNowGems(),_("金龙币不足")
end

function GameUIUpgradeTechnology:GetUpgradeGemsIfResourceNotEnough()
    local coin = City.resource_manager:GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local materialManager = City:GetMaterialManager()
    local resource,material,__ = self:GetNeedResourceAndMaterialsAndTime()
    local resource_gems = DataUtils:buyResource(resource,{coin = coin})
    local blueprints = materialManager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["blueprints"]
    local tools = materialManager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["tools"]
    local pulley = materialManager:GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)["pulley"]
    local material_gems = DataUtils:buyMaterial(material,{blueprints = blueprints,tools = tools,pulley = pulley})
    return resource_gems + material_gems
end

function GameUIUpgradeTechnology:GetUpgradeGemsIfQueueNotEnough()
    if City:HaveProductionTechEvent() then
        local event = City:GetProductionTechEventsArray()[1]
        return DataUtils:getGemByTimeInterval(event:GetTime())
    end
end

function GameUIUpgradeTechnology:CheckCanUpgradeActionReturnGems()
    if not self:CheckUpgradeButtonState() then
        return -1
    end
    local gems_cost,msg = 0,""
    if City:HaveProductionTechEvent() then
        gems_cost = self:GetUpgradeGemsIfQueueNotEnough()
        msg = _("已有科技升级队列,需加速完成该队列花费金龙币") .. gems_cost.. "\n"
    end
    local resource_gems = self:GetUpgradeGemsIfResourceNotEnough()
    if resource_gems ~= 0 then
        gems_cost = resource_gems + gems_cost
        msg = msg  .. _("升级所需物品不足,购买所缺物品需花费金龙币") .. resource_gems.. "\n"
    end
    return gems_cost,msg
end

function GameUIUpgradeTechnology:RefreshButtonState()
    self.upgradeNowButton.button:setButtonEnabled(self:CheckUpgradeNowButtonState())
    self.upgrade_button.button:setButtonEnabled(self:CheckUpgradeButtonState())
end

function GameUIUpgradeTechnology:CheckUpgradeButtonState()
    if not self:CheckMeIsOpened() 
        or not self:CheckMeDependTechIsUnlock() 
        or self:CheckIsMeUpgrade() 
        or not self:CheckAcademyLevel()
        then
        return false
    end
    return true
end

function GameUIUpgradeTechnology:CheckUpgradeNowButtonState()
    if not self:CheckMeIsOpened() 
        or not self:CheckMeDependTechIsUnlock() 
        or self:CheckIsMeUpgrade() 
        or not self:CheckAcademyLevel()
        then
        return false
    end
    return true
end

function GameUIUpgradeTechnology:CheckAcademyLevel()
    local current_tech = self:GetProductionTechnology()
    return current_tech:AcademyLevel() <= City:GetAcademyBuildingLevel()
end

function GameUIUpgradeTechnology:CheckIsMeUpgrade()
    local current_tech = self:GetProductionTechnology()
    local event = self:GetEventInUpgradeQueue()
    if event then
        if event and event:Name() == current_tech:Name() then
            return true
        end
    end
    return false
end

function GameUIUpgradeTechnology:CheckMeIsOpened()
    return self:GetProductionTechnology():IsOpen()
end

function GameUIUpgradeTechnology:CheckMeDependTechIsUnlock()
    local current_tech = self:GetProductionTechnology()
    local unLockByTech = City:FindTechByIndex(current_tech:UnlockBy())
    return unLockByTech:Level() >= current_tech:UnlockLevel()
end

function GameUIUpgradeTechnology:GetEventInUpgradeQueue()
    if City:HaveProductionTechEvent() then
        return City:GetProductionTechEventsArray()[1]
    end
end

function GameUIUpgradeTechnology:CheckMeIsReachLimitLevel()
    local current_tech = self:GetProductionTechnology()
    if self:CheckIsMeUpgrade() then
        return current_tech:Level() + 1 >= current_tech:MaxLevel()
    else
        return current_tech:IsReachLimitLevel()
    end
end

return GameUIUpgradeTechnology



