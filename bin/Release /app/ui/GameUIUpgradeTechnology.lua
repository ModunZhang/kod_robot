--
-- Author: Danny He
-- Date: 2014-12-17 19:30:23
--
local Localize = import("..utils.Localize")
local GameUIUpgradeTechnology = UIKit:createUIClass("GameUIUpgradeTechnology","UIAutoClose")
local WidgetUIBackGround = import("..widget.WidgetUIBackGround")
local WidgetRequirementListview = import("..widget.WidgetRequirementListview")
local HEIGHT = 760
local window = import("..utils.window")

function GameUIUpgradeTechnology:ctor(tech)
    self.tech = tech
    self.tech_name = User:GetProductionTech(tech.index)
    GameUIUpgradeTechnology.super.ctor(self)
end
function GameUIUpgradeTechnology:GetTech()
    return self.tech, self.tech_name
end

function GameUIUpgradeTechnology:onEnter()
    GameUIUpgradeTechnology.super.onEnter(self)
    if self:CheckIsMeUpgrade() then
        HEIGHT = 616
    else
        if self:CheckMeIsReachLimitLevel() then
            HEIGHT = 266
        else
            HEIGHT = 760
        end
    end
    self:BuildUI()
    self:RefreshButtonState()
    User:AddListenOnType(self, "productionTechs")
end

function GameUIUpgradeTechnology:OnMoveOutStage()
    User:RemoveListenerOnType(self, "productionTechs")
    GameUIUpgradeTechnology.super.OnMoveOutStage(self)
end
function GameUIUpgradeTechnology:OnUserDataChanged_productionTechs(userData, deltaData)
    local ok, value = deltaData("productionTechs")
    if ok then
        for tech_name,v in pairs(value) do
            local tech = userData.productionTechs[tech_name]
            if type(self.GetTech) == 'function' and 
                self:GetTech().index == tech.index then
                if self:CheckMeIsReachLimitLevel() then
                    self:LeftButtonClicked()
                else
                    self:RefreshUI()
                end
            end
        end
    end
end

function GameUIUpgradeTechnology:GetTechLevelStr()
    local User = User
    local tech, tech_name = self:GetTech()
    if self:CheckIsMeUpgrade() and 
        not self:CheckMeIsReachLimitLevel() then
        return Localize.productiontechnology_name[tech_name] .. " " .. _("等级") .. " " .. (tech.level + 1)
    end
    return Localize.productiontechnology_name[tech_name] .. " " .. _("等级") .. " " .. tech.level
end

function GameUIUpgradeTechnology:GetResourceCost()
    local User = User
    local tech, tech_name = self:GetTech()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        return UtilsForTech:GetTechInfo(tech_name, tech.level + 2)
    end
    return UtilsForTech:GetTechInfo(tech_name, tech.level + 1)
end

function GameUIUpgradeTechnology:GetLevelUpBuffTimeStr()
    local buildTime = 0
    local tech, tech_name = self:GetTech()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        buildTime = UtilsForTech:GetTechInfo(tech_name, tech.level + 2).buildTime
    end
    buildTime = UtilsForTech:GetTechInfo(tech_name, tech.level + 1).buildTime
    return string.format("(-%s)",GameUtils:formatTimeStyle1(DataUtils:getTechnilogyUpgradeBuffTime(buildTime)))
end

function GameUIUpgradeTechnology:GetLevelUpTimeStr()
    local tech, tech_name = self:GetTech()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        return GameUtils:formatTimeStyle1(UtilsForTech:GetTechInfo(tech_name, tech.level + 2).buildTime)
    end
    return GameUtils:formatTimeStyle1(UtilsForTech:GetTechInfo(tech_name, tech.level + 1).buildTime)
end

function GameUIUpgradeTechnology:GetBuffEffectStr()
    local tech, tech_name = self:GetTech()
    return UtilsForTech:GetEffect(tech_name, tech) * 100  .. "%"
end

function GameUIUpgradeTechnology:GetPowerStr()
    local tech, tech_name = self:GetTech()
    local config = UtilsForTech:GetTechInfo(tech_name, tech.level)
    if config then
        return config.power
    end
    return 0
end

function GameUIUpgradeTechnology:GetNextLevelBuffEffectStr()
    local tech, tech_name = self:GetTech()
    return UtilsForTech:GetNextLevelEffect(tech_name, tech) * 100  .. "%"
end

function GameUIUpgradeTechnology:GetNextLevelPower()
    if self:CheckIsMeUpgrade() and not self:CheckMeIsReachLimitLevel() then
        local tech, tech_name = self:GetTech()
        local power = UtilsForTech:GetTechInfo(tech_name, tech.level + 1).power
        if power > 0 then
            return power
        else
            return 0
        end
    end
    local tech, tech_name = self:GetTech()
    local power = UtilsForTech:GetTechInfo(tech_name, tech.level + 1).power
    return power
end

function GameUIUpgradeTechnology:RefreshUI()
    local tech, tech_name = self:GetTech()
    self.lv_label:setString(self:GetTechLevelStr())
    self.current_effect_val_label:setString(self:GetBuffEffectStr())
    self.current_power_val_label:setString(self:GetPowerStr())
    if not UtilsForTech:IsMaxLevel(tech_name, tech) then
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
    local tech, tech_name = self:GetTech()
    local icon_image = UtilsForTech:GetProductionTechImage(tech_name)
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
    bg.changeState(User:IsTechEnable(tech_name, self:GetTech()))
    return bg
end

function GameUIUpgradeTechnology:BuildUI()
    local y = window.top_bottom - 50
    if HEIGHT == 266 then
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

    local title = display.newScale9Sprite("title_blue_430x30.png",0,0, cc.size(438,30), cc.rect(10,10,410,10))
        :align(display.LEFT_TOP,box:getPositionX()+box:getContentSize().width + 10, box:getPositionY())
        :addTo(bg_node)
    self.lv_label = UIKit:ttfLabel({
        text = self:GetTechLevelStr(),
        size = 22,
        color= 0xffedae
    }):align(display.LEFT_CENTER, 10, 15):addTo(title)
     
    local tech, tech_name = self:GetTech()
    UIKit:ttfLabel({
        text = Localize.productiontechnology_buffer[tech_name],
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_BOTTOM,box:getPositionX() + box:getContentSize().width + 20, box:getPositionY()-box:getContentSize().height/2):addTo(bg_node)
    local line_2 = display.newScale9Sprite("dividing_line.png",0,0,cc.size(544,2),cc.rect(10,2,382,2))
        :align(display.LEFT_BOTTOM,box:getPositionX() + 8, box:getPositionY()-box:getContentSize().height - 82)
        :addTo(bg_node)
    local line_1 =  display.newScale9Sprite("dividing_line.png",0,0,cc.size(544,2),cc.rect(10,2,382,2))
        :align(display.LEFT_BOTTOM,line_2:getPositionX(), line_2:getPositionY() + 40)
        :addTo(bg_node)
    self.line_1 = line_1
    local current_effect_desc = UIKit:ttfLabel({
        text = _("当前效果"),
        size = 20,
        color= 0x615b44
    }):align(display.LEFT_BOTTOM,line_1:getPositionX()+6, line_1:getPositionY() + 5):addTo(bg_node)
    local next_effect_val_label = UIKit:ttfLabel({
        text = "",
        size = 22,
        color= 0x403c2f,
        align = cc.TEXT_ALIGNMENT_RIGHT,
    }):align(display.RIGHT_BOTTOM,line_1:getPositionX()+ 544,current_effect_desc:getPositionY()):addTo(bg_node)
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
    }):align(display.RIGHT_BOTTOM,line_2:getPositionX()+ 544,current_power_desc:getPositionY()):addTo(bg_node)
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
    if not UtilsForTech:IsMaxLevel(tech_name, tech) then
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
    local User = User
    local requirements = {}
    local current_tech, current_tech_name = self:GetTech()
    local current_tech_info = UtilsForTech:GetProductionTechConfig(current_tech_name)

    local tech_name, unLockByTech = User:GetProductionTech(current_tech_info.unlockBy)
    local cost = self:GetResourceCost()
    local coin = User:GetResValueByType("coin")
    table.insert(requirements,
        {
            resource_type = _("升级队列"),
            isVisible = true,
            isSatisfy = not User:HasProductionTechEvent(),
            icon="hammer_33x40.png",
            description= User:HasProductionTechEvent() and "0/1" or "1/1"
        })
    if unLockByTech.index ~= current_tech.index then
        table.insert(requirements,
            {
                resource_type = UtilsForTech:GetTechLocalize(tech_name),
                isVisible = true,
                isSatisfy = unLockByTech.level >= current_tech_info.unlockLevel,
                icon= UtilsForTech:GetProductionTechImage(tech_name),
                description= _("等级达到") .. current_tech_info.unlockLevel,
                canNotBuy = true,
            })
    end
    table.insert(requirements,
        {
            resource_type = _("学院等级"),
            isVisible = true,
            isSatisfy = current_tech_info.academyLevel <= User:GetAcademyLevel(),
            icon="academy.png",
            description = _("等级达到") .. current_tech_info.academyLevel,
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
            resource_type = _("工程图纸"),
            isVisible = cost.blueprints>0,
            isSatisfy = User.buildingMaterials["blueprints"]>=cost.blueprints,
            icon="blueprints_128x128.png",
            description= User.buildingMaterials["blueprints"] .."/"..  cost.blueprints
        })
    table.insert(requirements,
        {
            resource_type = _("建造工具"),
            isVisible = cost.tools>0,
            isSatisfy = User.buildingMaterials["tools"]>=cost.tools,
            icon="tools_128x128.png",
            description= User.buildingMaterials["tools"] .."/".. cost.tools
        })
    table.insert(requirements,
        {
            resource_type = _("砖石瓦片"),
            isVisible = cost.tiles>0,
            isSatisfy = User.buildingMaterials["tiles"]>=cost.tiles,
            icon="tiles_128x128.png",
            description= User.buildingMaterials["tiles"] .. "/" .. cost.tiles
        })
    table.insert(requirements,
        {
            resource_type = _("滑轮组"),
            isVisible = cost.pulley>0,
            isSatisfy = User.buildingMaterials["pulley"]>=cost.pulley,
            icon="pulley_128x128.png",
            description = User.buildingMaterials["pulley"] .. "/" .. cost.pulley
        })

    -- table.sort( requirements, function(a,b)
    --     return not a.isSatisfy and b.isSatisfy
    -- end)
    return requirements
end

function GameUIUpgradeTechnology:OnUpgradNowButtonClicked()
    local canUpgrade,msg = self:CheckCanUpgradeNow()
    if canUpgrade then
        if app:GetGameDefautlt():IsOpenGemRemind() then
            UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                string.formatnumberthousands(self:GetUpgradeNowGems())
            ), function()
                local current_tech,current_tech_name = self:GetTech()
                NetManager:getUpgradeProductionTechPromise(current_tech_name,true)
            end,true,true)
        else
            local current_tech,current_tech_name = self:GetTech()
            NetManager:getUpgradeProductionTechPromise(current_tech_name,true)
        end
    else
        UIKit:showMessageDialog(_("提示"),msg, function()end)
    end
end

function GameUIUpgradeTechnology:OnUpgradButtonClicked()
    local gems_cost,msg = self:CheckCanUpgradeActionReturnGems()
    if gems_cost < 0 then
        return
    elseif gems_cost == 0 then
        local current_tech,current_tech_name = self:GetTech()
        NetManager:getUpgradeProductionTechPromise(current_tech_name,false):done(function()
            self:LeftButtonClicked()
            local acdemy = UIKit:GetUIInstance("GameUIAcademy")
            if acdemy then
                acdemy:LeftButtonClicked()
            end
            local quick = UIKit:GetUIInstance("GameUIQuickTechnology")
            if quick then
                quick:LeftButtonClicked()
            end
        end)
    else
        UIKit:showMessageDialog(_("提示"),msg):CreateOKButtonWithPrice(
            {
                listener = function()
                    self:ForceUpgrade(gems_cost)
                end,
                btn_images = {normal = "green_btn_up_148x58.png",pressed = "green_btn_down_148x58.png"},
                price = gems_cost
            }
        ):CreateCancelButton()
    end
end

function GameUIUpgradeTechnology:ForceUpgrade(gem_cost)
    if  User:GetGemValue() < gem_cost then
        UIKit:showMessageDialog(_("提示"),_("金龙币不足"), function()
            UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
            self:LeftButtonClicked()
        end)
    else
        local current_tech,current_tech_name = self:GetTech()
        NetManager:getUpgradeProductionTechPromise(current_tech_name, false):done(function(msg)
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
            tiles      = cost.tiles,
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
    return User:GetGemValue() >= self:GetUpgradeNowGems(),_("金龙币不足")
end

function GameUIUpgradeTechnology:GetUpgradeGemsIfResourceNotEnough()
    local User = User
    local coin = User:GetResValueByType("coin")
    local resource,material,__ = self:GetNeedResourceAndMaterialsAndTime()
    local resource_gems = DataUtils:buyResource(resource,{coin = coin})
    local blueprints = User.buildingMaterials["blueprints"]
    local tools = User.buildingMaterials["tools"]
    local pulley = User.buildingMaterials["pulley"]
    local tiles = User.buildingMaterials["tiles"]
    local material_gems = DataUtils:buyMaterial(material,{blueprints = blueprints,tools = tools,pulley = pulley,tiles = tiles})
    return resource_gems + material_gems
end

function GameUIUpgradeTechnology:GetUpgradeGemsIfQueueNotEnough()
    if User:HasProductionTechEvent() then
        local event = User.productionTechEvents[1]
        local time = UtilsForEvent:GetEventInfo(event)
        return DataUtils:getGemByTimeInterval(time)
    end
end

function GameUIUpgradeTechnology:CheckCanUpgradeActionReturnGems()
    if not self:CheckUpgradeButtonState() then
        return -1
    end
    local gems_cost,msg = 0,""
    if User:HasProductionTechEvent() then
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
    local current_tech,current_tech_name = self:GetTech()
    local current_tech_info = UtilsForTech:GetProductionTechConfig(current_tech_name)
    return current_tech_info.academyLevel <= User:GetAcademyLevel()
end

function GameUIUpgradeTechnology:CheckIsMeUpgrade()
    local current_tech,current_tech_name = self:GetTech()
    local event = self:GetEventInUpgradeQueue()
    if event and event.name == current_tech_name then
        return true
    end
    return false
end

function GameUIUpgradeTechnology:CheckMeIsOpened()
    return true
end

function GameUIUpgradeTechnology:CheckMeDependTechIsUnlock()
    local current_tech,current_tech_name = self:GetTech()
    local current_tech_info = UtilsForTech:GetProductionTechConfig(current_tech_name)
    local _,unLockByTech = User:GetProductionTech(current_tech_info.unlockBy)
    return unLockByTech.level >= current_tech_info.unlockLevel
end

function GameUIUpgradeTechnology:GetEventInUpgradeQueue()
    if User:HasProductionTechEvent() then
        return User.productionTechEvents[1]
    end
end

function GameUIUpgradeTechnology:CheckMeIsReachLimitLevel()
    local current_tech,current_tech_name = self:GetTech()
    if self:CheckIsMeUpgrade() then
        return current_tech.level + 1 >= UtilsForTech:MaxLevel(current_tech_name)
    else
        return current_tech.level >= UtilsForTech:MaxLevel(current_tech_name)
    end
end

return GameUIUpgradeTechnology







