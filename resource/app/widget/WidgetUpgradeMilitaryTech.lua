--
-- Author: Kenny Dai
-- Date: 2015-01-20 10:39:47
--
local WidgetPopDialog = import(".WidgetPopDialog")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local MilitaryTechnology = import("..entity.MilitaryTechnology")
local WidgetRequirementListview = import(".WidgetRequirementListview")
local MaterialManager = import("..entity.MaterialManager")
local SoldierManager = import("..entity.SoldierManager")


local WidgetUpgradeMilitaryTech = class("WidgetUpgradeMilitaryTech", WidgetPopDialog)

local function create_line_item(icon,text_1,text_2)
    local line = display.newSprite("dividing_line_546x2.png")
    local icon = display.newSprite(icon):addTo(line,2):align(display.LEFT_BOTTOM, 0, 0)
    icon:scale(40/icon:getContentSize().width)
    local text1 = UIKit:ttfLabel({
        text = text_1,
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_BOTTOM, 50 , 0)
        :addTo(line)
    local text2 = UIKit:ttfLabel({
        text = text_2,
        size = 20,
        color = 0x007c23,
    }):align(display.RIGHT_BOTTOM, 540 , 0)
        :addTo(line)

    function line:SetText(text)
        text2:setString(text)
    end

    return line
end
function WidgetUpgradeMilitaryTech:ctor(tech)
    WidgetUpgradeMilitaryTech.super.ctor(self,694,_("研发军事科技"))
    self.tech =  City:GetSoldierManager():GetMilitaryTechsByName(tech:Name())
end

function WidgetUpgradeMilitaryTech:onEnter()
    WidgetUpgradeMilitaryTech.super.onEnter(self)
    self:CurrentInfo()
    self:UpgradeButtons()
    self:UpgradeRequirement()

    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    City:GetMaterialManager():AddObserver(self)
    City:GetResourceManager():AddObserver(self)
end
function WidgetUpgradeMilitaryTech:onExit()
    City:GetMaterialManager():RemoveObserver(self)
    City:GetResourceManager():RemoveObserver(self)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    WidgetUpgradeMilitaryTech.super.onExit(self)
end
function WidgetUpgradeMilitaryTech:CurrentInfo()
    local body = self.body
    local size = body:getContentSize()
    local bg = display.newScale9Sprite("back_ground_548x52.png", 0, 0,cc.size(548,46),cc.rect(10,10,528,26))
        :align(display.CENTER, size.width/2, size.height-50)
        :addTo(body)

    local tech = self.tech
    self.upgrade_tip = UIKit:ttfLabel({
        text = tech:GetTechLocalize().." (".._("升级到").." Lv"..(tech:Level()+1)..")",
        size = 22,
        color = 0x403c2f,
    }):align(display.CENTER, bg:getContentSize().width/2 , bg:getContentSize().height/2)
        :addTo(bg)
    self.line1 = create_line_item("battle_33x33.png",tech:GetTechLocalize(),"+"..(tech:GetNextLevlAtkEff()*100).."%"):addTo(body):align(display.CENTER, size.width/2, size.height-120)
    self.line2 = create_line_item("bottom_icon_package_77x67.png",tech:GetTechCategory(),"+"..tech:GetNextLevlTechPoint()):addTo(body):align(display.CENTER, size.width/2, size.height-170)
end
function WidgetUpgradeMilitaryTech:UpgradeButtons()
    local body = self.body
    local size = body:getContentSize()
    -- upgrade now button
    local btn_bg = UIKit:commonButtonWithBG(
        {
            w=250,
            h=65,
            style = UIKit.BTN_COLOR.GREEN,
            labelParams = {text = _("立即研发")},
            listener = function ()
                local upgrade_listener = function()
                    NetManager:getInstantUpgradeMilitaryTechPromise(self.tech:Name())
                end

                if self.tech:IsAbleToUpgradeNow() then
                    UIKit:showMessageDialog(_("陛下"),_("金龙币不足"))
                        :CreateOKButton({
                            listener =  function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                self:LeftButtonClicked()
                            end
                        })
                else
                    upgrade_listener()
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
            labelParams={text = _("研发")},
            listener = function ()
                local upgrade_listener = function()
                    NetManager:getUpgradeMilitaryTechPromise(self.tech:Name())
                    self:LeftButtonClicked()
                    local tech_ui = UIKit:GetUIInstance("GameUIMilitaryTechBuilding")
                    if tech_ui then
                        tech_ui:LeftButtonClicked()
                    end
                end

                local results = self.tech:IsAbleToUpgrade()

                if LuaUtils:table_empty(results) then
                    upgrade_listener()
                else
                    self:PopNotSatisfyDialog(upgrade_listener,results)
                end
            end,
        }
    ):pos(size.width/2+180, size.height-230)
        :addTo(body)


    -- 立即升级所需金龙币
    display.newSprite("gem_icon_62x61.png", size.width/2 - 250, size.height-290):addTo(body):setScale(0.5)
    self.upgrade_now_need_gems_label = UIKit:ttfLabel({
        text = self.tech:GetInstantUpgradeGems(),
        size = 20,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,size.width/2 - 230,size.height-294):addTo(body)
    --升级所需时间
    display.newSprite("hourglass_30x38.png", size.width/2+100, size.height-290):addTo(body):setScale(0.6)
    self.upgrade_time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(self.tech:GetUpgradeTime()),
        size = 18,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,size.width/2+125,size.height-280):addTo(body)

    -- 科技减少升级时间
    self.buff_reduce_time = UIKit:ttfLabel({
        text = "(-"..GameUtils:formatTimeStyle1(DataUtils:getTechnilogyUpgradeBuffTime(self.tech:GetUpgradeTime()))..")",
        size = 18,
        color = 0x068329
    }):align(display.LEFT_CENTER,size.width/2+120,size.height-300):addTo(body)
end
function WidgetUpgradeMilitaryTech:UpgradeRequirement()
    local tech = self.tech
    local body = self.body
    local size = body:getContentSize()
    local level_up_config = tech:GetLevelUpConfig()
    local has_materials = City:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.TECHNOLOGY)
    local current_coin = City:GetResourceManager():GetCoinResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())

    local requirements = {
        {
            resource_type = "building_queue",
            isVisible = City:GetSoldierManager():GetUpgradingMilitaryTechNum(self.tech:Building())>0,
            isSatisfy = not  City:GetSoldierManager():IsUpgradingMilitaryTech(self.tech:Building()),
            icon="hammer_31x33.png",
            description= _("升级队列已满")..":"..(1-City:GetSoldierManager():GetUpgradingMilitaryTechNum(self.tech:Building())).."/1"
        },
        {
            resource_type = Localize.fight_reward.coin,
            isVisible = level_up_config.coin>0,
            isSatisfy = current_coin>level_up_config.coin,
            icon=UILib.resource.coin,description=current_coin..'/'..level_up_config.coin
        },
        {
            resource_type = Localize.sell_type.trainingFigure,
            isVisible = level_up_config.trainingFigure>0,
            isSatisfy = has_materials.trainingFigure>level_up_config.trainingFigure,
            icon=UILib.materials.trainingFigure,
            description=has_materials.trainingFigure..'/'..level_up_config.trainingFigure
        },
        {
            resource_type = Localize.sell_type.bowTarget,
            isVisible = level_up_config.bowTarget>0,
            isSatisfy = has_materials.bowTarget>level_up_config.bowTarget,
            icon=UILib.materials.bowTarget,
            description=has_materials.bowTarget..'/'..level_up_config.bowTarget
        },
        {
            resource_type = Localize.sell_type.saddle,
            isVisible = level_up_config.saddle>0,
            isSatisfy = has_materials.saddle>level_up_config.saddle,
            icon=UILib.materials.saddle,
            description=has_materials.saddle..'/'..level_up_config.saddle
        },
        {
            resource_type = Localize.sell_type.ironPart,
            isVisible = level_up_config.ironPart>0,
            isSatisfy = has_materials.ironPart>level_up_config.ironPart,
            icon=UILib.materials.ironPart,
            description=has_materials.ironPart..'/'..level_up_config.ironPart
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
function WidgetUpgradeMilitaryTech:OnResourceChanged()
    self:UpgradeRequirement()
end
function WidgetUpgradeMilitaryTech:OnMaterialsChanged(material_manager, material_type, changed)
    if material_type == MaterialManager.MATERIAL_TYPE.TECHNOLOGY then
        self:UpgradeRequirement()
    end
end
function WidgetUpgradeMilitaryTech:PopNotSatisfyDialog(upgrade_listener,results)
    local message = ""
    for k,v in pairs(results) do
        message = message .. v.."\n"
    end
    local need_gems = self.tech:GetUpgradeGems()
    local current_gem = User:GetGemResource():GetValue()
    UIKit:showMessageDialog(_("陛下"),message)
        :CreateOKButton({
            listener =  current_gem < need_gems and function ()
                UIKit:showMessageDialog(_("陛下"),_("金龙币不足"))
                    :CreateOKButton({
                        listener =  function ()
                            UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            self:LeftButtonClicked()
                        end
                    })
            end
            or upgrade_listener
        })
        :CreateNeeds({value = need_gems})
end
function WidgetUpgradeMilitaryTech:OnMilitaryTechsDataChanged(city,changed_map)
    for k,v in pairs(changed_map) do
        if v:Name() == self.tech:Name() then
            if v:IsMaxLevel() then
                self:LeftButtonClicked()
                return
            end
            self.tech = v
            self.upgrade_time:setString(GameUtils:formatTimeStyle1(v:GetUpgradeTime()))
            self.upgrade_now_need_gems_label:setString(v:GetInstantUpgradeGems())
            self.upgrade_tip:setString(v:GetTechLocalize().." (".._("升级到").." Lv"..(v:Level()+1)..")")
            self.line1:SetText("+"..(v:GetAtkEff()*100).."%")
            self.line2:SetText("+"..v:GetTechPoint())
            self:UpgradeRequirement()
        end
    end
end
return WidgetUpgradeMilitaryTech














