--
-- Author: Kenny Dai
-- Date: 2015-01-21 11:06:57
--
local WidgetPopDialog = import(".WidgetPopDialog")
local StarBar = import("..ui.StarBar")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local WidgetRequirementListview = import(".WidgetRequirementListview")
local MaterialManager = import("..entity.MaterialManager")
local SoldierManager = import("..entity.SoldierManager")
local NORMAL = GameDatas.Soldiers.normal

local WidgetPromoteSoldier = class("WidgetPromoteSoldier", WidgetPopDialog)

function WidgetPromoteSoldier:ctor(soldier_type,building_type)
    WidgetPromoteSoldier.super.ctor(self,780,_("兵种晋级"))
    self.soldier_type = soldier_type
    self.building_type = building_type
    self.star = City:GetSoldierManager():GetStarBySoldierType(soldier_type)
end

function WidgetPromoteSoldier:onEnter()
    WidgetPromoteSoldier.super.onEnter(self)
    self:SoldierImage()
    self:UpgradeButtons()
    self:UpgradeRequirement()

    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    City:GetResourceManager():AddObserver(self)
end
function WidgetPromoteSoldier:onExit()
    City:GetResourceManager():RemoveObserver(self)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.SOLDIER_STAR_CHANGED)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    WidgetPromoteSoldier.super.onExit(self)
end
function WidgetPromoteSoldier:SoldierImage()
    local body = self.body
    local size = body:getContentSize()
    local soldier_type = self.soldier_type
    local star = self.star
    -- 士兵图片
    self.current_soldier = self:CreateSoldierBox(false):addTo(body):align(display.CENTER, 114, size.height-100)
    self.next_soldier = self:CreateSoldierBox(true):addTo(body):align(display.CENTER, 494, size.height-100)
    -- line
    display.newScale9Sprite("box_light_70x32.png",size.width/2,size.height-100,cc.size(246,32),cc.rect(10,8,50,16)):addTo(body)
end
function WidgetPromoteSoldier:CreateSoldierBox(isGray)
    local soldier_type = self.soldier_type
    local star = isGray and self.star +1 or self.star
    local soldier_box = display.newSprite("box_light_148x148.png")
    local blue_bg = display.newSprite("back_ground_121x122.png", soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)

    local soldier_icon = display.newSprite(UILib.soldier_image[soldier_type][star], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
    soldier_icon:scale(124/math.max(soldier_icon:getContentSize().width,soldier_icon:getContentSize().height))
    if isGray then
        local my_filter = filter
        local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
        blue_bg:setFilter(filters)
        soldier_icon:setFilter(filters)
    end
    soldier_box.soldier_icon = soldier_icon
    local soldier_star_bg = display.newSprite("tmp_back_ground_102x22.png"):addTo(soldier_icon):align(display.BOTTOM_CENTER,soldier_icon:getContentSize().width/2-16, 0)
    StarBar.new({
        max = 3,
        bg = "Stars_bar_bg.png",
        fill = "Stars_bar_highlight.png",
        num = star,
        margin = 5,
        direction = StarBar.DIRECTION_HORIZONTAL,
        scale = 0.8,
    }):addTo(soldier_star_bg):align(display.CENTER,58, 11)
    function soldier_box:SetSoldierIcon(isNext)
        local current_star = City:GetSoldierManager():GetStarBySoldierType(soldier_type)
        local star = isNext and current_star+1 or current_star
        self:removeChild(self.soldier_icon, true)

        local soldier_icon = display.newSprite(UILib.soldier_image[soldier_type][star], soldier_box:getContentSize().width/2, soldier_box:getContentSize().height/2, {class=cc.FilteredSpriteWithOne}):addTo(soldier_box)
        soldier_icon:scale(124/math.max(soldier_icon:getContentSize().width,soldier_icon:getContentSize().height))
        if isNext then
            local my_filter = filter
            local filters = my_filter.newFilter("GRAY", {0.2, 0.3, 0.5, 0.1})
            blue_bg:setFilter(filters)
            soldier_icon:setFilter(filters)
        end
        self.soldier_icon = soldier_icon
    end
    return soldier_box
end
function WidgetPromoteSoldier:UpgradeButtons()
    local body_1 = self.body
    local size = body_1:getContentSize()
    self.upgrade_body = display.newNode():addTo(body_1)
    local body =  self.upgrade_body
    body:setContentSize(size)
    -- upgrade now button
    self.btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即晋级")},
            listener = function ()
                local upgrade_listener = function()
                    NetManager:getInstantUpgradeSoldierStarPromise(self.soldier_type)
                end

                local results = self:IsAbleToUpgradeNow()
                if LuaUtils:table_empty(results) then
                    if app:GetGameDefautlt():IsOpenGemRemind() then
                        UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                            string.formatnumberthousands(self:GetInstantUpgradeGems())
                        ), function()
                            upgrade_listener()
                        end,true,true)
                    else
                        upgrade_listener()
                    end
                else
                    self:PopNotSatisfyDialog(function ()end,results)
                end
            end,
        }
    ):pos(size.width/2-140, size.height-230)
        :addTo(body)

    -- upgrade button
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=185,
            h=65,
            style = UIKit.BTN_COLOR.YELLOW,
            labelParams={text = _("晋级")},
            listener = function ()
                local upgrade_listener = function()
                    NetManager:getUpgradeSoldierStarPromise(self.soldier_type)
                    self:LeftButtonClicked()
                end

                local results = self:IsAbleToUpgradeFirst()
                if not LuaUtils:table_empty(results) then
                    self:PopNotSatisfyDialog(function ()end,results)
                    return
                end
                local results = self:IsAbleToUpgradeSecond()
                if LuaUtils:table_empty(results) then
                    upgrade_listener()
                else
                    local dialog =  self:PopNotSatisfyDialog(upgrade_listener,results)
                    local need_gem = self:GetUpgradeGems()
                    if need_gem > User:GetGemResource():GetValue() then
                        dialog:CreateOKButton({
                            listener =  function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            end,
                            btn_name = _("前往商店")
                        })
                    else
                        dialog:CreateOKButtonWithPrice({
                            listener =  upgrade_listener,
                            price = need_gem
                        }):CreateCancelButton()
                    end
                end
            end,
        }
    ):pos(size.width/2+180, size.height-230)
        :addTo(body)


    -- 立即升级所需金龙币
    display.newSprite("gem_icon_62x61.png", size.width/2 - 250, size.height-290):addTo(body):setScale(0.5)
    self.upgrade_now_need_gems_label = UIKit:ttfLabel({
        text = self:GetInstantUpgradeGems(),
        size = 20,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,size.width/2 - 230,size.height-294):addTo(body)
    --升级所需时间
    local level_up_config = self:GetNextLevelConfig()

    display.newSprite("hourglass_30x38.png", size.width/2+100, size.height-290):addTo(body):setScale(0.6)
    self.upgrade_time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(level_up_config.upgradeTimeSecondsNeed),
        size = 18,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,size.width/2+125,size.height-294):addTo(body)

end
function WidgetPromoteSoldier:UpgradeRequirement()
    local body = self.body
    local size = body:getContentSize()
    local level_up_config = self:GetNextLevelConfig()
    if not level_up_config then
        return
    end
    local current_coin = City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())

    local tech_points = City:GetSoldierManager():GetTechPointsByType(self:GetSoldierMapToBuilding())
    local requirements = {
        {
            resource_type = "building_queue",
            isVisible = City:GetSoldierManager():GetUpgradingMilitaryTechNum(self.building_type)>0,
            isSatisfy = not  City:GetSoldierManager():IsUpgradingMilitaryTech(self.building_type),
            icon="hammer_33x40.png",
            description= string.format( _("升级队列已满:%d/1"), 1-City:GetSoldierManager():GetUpgradingMilitaryTechNum(self.building_type) )
        },
        {
            resource_type = Localize.fight_reward.coin,
            isVisible = level_up_config.upgradeCoinNeed>0,
            isSatisfy = current_coin>level_up_config.upgradeCoinNeed,
            icon=UILib.resource.coin,
            description=current_coin..'/'..level_up_config.upgradeCoinNeed
        },
        {
            resource_type = _("科技点数"),
            isVisible = level_up_config.upgradeTechPointNeed>0,
            isSatisfy =tech_points>=level_up_config.upgradeTechPointNeed,
            icon="bottom_icon_package_77x67.png",
            description=tech_points..'/'..level_up_config.upgradeTechPointNeed,
            canNotBuy = true
        },
    }

    if not self.requirement_listview then
        self.requirement_listview = WidgetRequirementListview.new({
            title = _("升级需求"),
            height = 270,
            contents = requirements,
        }):addTo(body):pos(32,size.height-650)
    end
    self.requirement_listview:RefreshListView(requirements)
end
function WidgetPromoteSoldier:GetSoldierMapToBuilding()
    local soldier_type = self.soldier_type
    if soldier_type == "sentinel" or soldier_type =="swordsman" then
        return "trainingGround"
    elseif soldier_type == "horseArcher" or soldier_type =="lancer" then
        return "stable"
    elseif soldier_type == "ranger" or soldier_type =="crossbowman" then
        return "hunterHall"
    elseif soldier_type == "ballista" or soldier_type =="catapult" then
        return "workshop"
    end
end
function WidgetPromoteSoldier:UpgradeFinishRefresh()
    self:UpgradeRequirement()
    self.upgrade_time:setString(GameUtils:formatTimeStyle1(self:GetNextLevelConfig().upgradeTimeSecondsNeed))
    self.upgrade_now_need_gems_label:setString(self:GetInstantUpgradeGems())
    self.current_soldier:SetSoldierIcon(false)
    self.next_soldier:SetSoldierIcon(true)
end
function WidgetPromoteSoldier:OnResourceChanged()
    self:UpgradeRequirement()
end
function WidgetPromoteSoldier:OnSoliderStarCountChanged(soldier_manager,changed_map)
    for i,v in ipairs(changed_map) do
        if v == self.soldier_type then
            if City:GetSoldierManager():GetSoldierMaxStar() == City:GetSoldierManager():GetStarBySoldierType(v) then
                self:LeftButtonClicked()
            else
                self:UpgradeFinishRefresh()
            end
        end
    end
end
function WidgetPromoteSoldier:OnMilitaryTechsDataChanged( soldier_manager,changed_map )
    self:UpgradeRequirement()
end
function WidgetPromoteSoldier:PopNotSatisfyDialog(upgrade_listener,results)
    local message = ""
    for k,v in pairs(results) do
        message = message .. v.."\n"
    end
    local dialog = UIKit:showMessageDialog(_("主人"),message)
    return dialog
end
function WidgetPromoteSoldier:GetInstantUpgradeGems()
    local config = self:GetNextLevelConfig()
    return DataUtils:buyResource({coin = config.upgradeCoinNeed}, {}) + DataUtils:getGemByTimeInterval(config.upgradeTimeSecondsNeed)
end
function WidgetPromoteSoldier:GetUpgradeGems()
    local config = self:GetNextLevelConfig()
    local current_coin = City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    -- 正在升级的军事科技剩余升级时间
    local left_time = City:GetSoldierManager():GetUpgradingMitiTaryTechLeftTimeByCurrentTime(self.building_type)
    return DataUtils:buyResource({coin = config.upgradeCoinNeed}, {coin=current_coin}) + DataUtils:getGemByTimeInterval(left_time)

end
function WidgetPromoteSoldier:IsAbleToUpgradeNow()
    local level_up_config = self:GetNextLevelConfig()

    local tech_points = City:GetSoldierManager():GetTechPointsByType(self:GetSoldierMapToBuilding())
    local results = {}
    if tech_points<level_up_config.upgradeTechPointNeed then
        table.insert(results, _("科技点未达到要求"))
    end
    if self:GetInstantUpgradeGems() > User:GetGemResource():GetValue() then
        table.insert(results, _("金龙币不足"))
    end
    return results
end
function WidgetPromoteSoldier:IsAbleToUpgradeFirst()
    local level_up_config = self:GetNextLevelConfig()
    local tech_points = City:GetSoldierManager():GetTechPointsByType(self:GetSoldierMapToBuilding())
    local results = {}
    if tech_points<level_up_config.upgradeTechPointNeed then
        table.insert(results, _("科技点未达到要求"))
    end
    return results
end
function WidgetPromoteSoldier:IsAbleToUpgradeSecond()
    local level_up_config = self:GetNextLevelConfig()
    local current_coin = City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local results = {}
    if City:GetSoldierManager():IsUpgradingMilitaryTech(self.building_type) then
        table.insert(results, _("升级军事科技队列被占用"))
    end
    if current_coin<level_up_config.upgradeCoinNeed then
        table.insert(results, string.format( _("银币不足 需要补充 %d"), level_up_config.upgradeCoinNeed-current_coin ) )
    end


    return results
end
function WidgetPromoteSoldier:GetNextLevelConfig()
    return NORMAL[self.soldier_type.."_"..(City:GetSoldierManager():GetStarBySoldierType(self.soldier_type)+1)]
end
return WidgetPromoteSoldier












