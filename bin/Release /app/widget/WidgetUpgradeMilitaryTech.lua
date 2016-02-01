--
-- Author: Kenny Dai
-- Date: 2015-01-20 10:39:47
--
local WidgetPopDialog = import(".WidgetPopDialog")
local window = import("..utils.window")
local Localize = import("..utils.Localize")
local UILib = import("..ui.UILib")
local WidgetRequirementListview = import(".WidgetRequirementListview")


local WidgetUpgradeMilitaryTech = class("WidgetUpgradeMilitaryTech", WidgetPopDialog)

local function create_line_item(icon,text_1,text_2,text_3)
    local line = display.newScale9Sprite("dividing_line.png",0,0,cc.size(412,2),cc.rect(10,2,382,2))
    local icon = display.newSprite(icon):addTo(line,2):align(display.LEFT_BOTTOM, 0, 2)
    icon:scale(32/math.max(icon:getContentSize().width,icon:getContentSize().height))
    local text1 = UIKit:ttfLabel({
        text = text_1,
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_BOTTOM, 40 , 2)
        :addTo(line)

    local green_icon = display.newSprite("teach_upgrade_icon_15x17.png"):align(display.BOTTOM_CENTER, 340 , 6):addTo(line)
    if text_2 == "" then
        green_icon:hide()
    end
    local text2 = UIKit:ttfLabel({
        text = text_2,
        size = 22,
        color = 0x403c2f,
    }):align(display.RIGHT_BOTTOM, green_icon:getPositionX() - 20 , 2)
        :addTo(line)
    local text3 = UIKit:ttfLabel({
        text = text_3,
        size = 22,
        color = 0x403c2f,
    }):align(display.LEFT_BOTTOM, green_icon:getPositionX() + 16 , 2)
        :addTo(line)

    function line:SetText(text_2,text_3)
        text3:setString(text_3)
        if text_2 then
            text2:setString(text_2)
        else
            text2:setString("")
            green_icon:hide()
        end
    end

    return line
end
function WidgetUpgradeMilitaryTech:ctor(name, military_tech)
    WidgetUpgradeMilitaryTech.super.ctor(self,694,_("研发军事科技"))
    self.tech_name = name
    self.tech = military_tech
end

function WidgetUpgradeMilitaryTech:onEnter()
    WidgetUpgradeMilitaryTech.super.onEnter(self)
    self:CurrentInfo()
    self:UpgradeButtons()
    scheduleAt(self, function()
        self:UpgradeRequirement()
    end)
    User:AddListenOnType(self, "militaryTechs")
end
function WidgetUpgradeMilitaryTech:onExit()
    User:RemoveListenerOnType(self, "militaryTechs")
    WidgetUpgradeMilitaryTech.super.onExit(self)
end
function WidgetUpgradeMilitaryTech:CurrentInfo()
    local body = self.body
    local size = body:getContentSize()
    local tech = self.tech

    local icon_box = display.newSprite("alliance_item_flag_box_126X126.png"):align(display.LEFT_CENTER, 40, size.height - 100):addTo(body)
    local icon_bg = display.newSprite("technology_bg_normal_142x142.png"):align(display.CENTER, icon_box:getContentSize().width/2, icon_box:getContentSize().height/2):addTo(icon_box):scale(0.8)
    display.newSprite(UtilsForTech:GetMiliTechIcon(self.tech_name)):align(display.CENTER, icon_bg:getContentSize().width/2, icon_bg:getContentSize().height/2):addTo(icon_bg)

    local bg = display.newScale9Sprite("title_blue_430x30.png",0,0,cc.size(412,30),cc.rect(15,10,400,10))
        :align(display.RIGHT_CENTER, size.width - 25, size.height-50)
        :addTo(body)

    self.upgrade_tip = UIKit:ttfLabel({
        text = UtilsForTech:GetTechLocalize(self.tech_name).." Lv" .. tech.level,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20 , bg:getContentSize().height/2)
        :addTo(bg)
    local soldiers = string.split(self.tech_name, "_")
    self.line1 = create_line_item(soldiers[2] == "hpAdd" and "tmp_icon_hp_18x28.png" or "battle_33x33.png",UtilsForTech:GetTechLocalize(self.tech_name),
    UtilsForTech:IsMaxLevel(self.tech_name, self.tech) and "" or (UtilsForTech:GetEffect(self.tech_name, self.tech)*100).."%",(UtilsForTech:GetNextLevelEffect(self.tech_name, self.tech)*100).."%"):addTo(body):align(display.LEFT_CENTER, icon_box:getPositionX() + icon_box:getContentSize().width + 5, size.height-120)
    self.line2 = create_line_item("bottom_icon_package_77x67.png",UtilsForTech:GetTechCategoryLocalize(self.tech),
        UtilsForTech:IsMaxLevel(self.tech_name, self.tech) and "" or UtilsForTech:GetTechPoint(self.tech_name, self.tech), UtilsForTech:GetNextLevelTechPoint(self.tech_name, self.tech)):addTo(body):align(display.LEFT_CENTER, self.line1:getPositionX(), size.height-164)
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
                    NetManager:getInstantUpgradeMilitaryTechPromise(self.tech_name)
                end

                if User:CanUpgradeNow(self.tech_name, self.tech) then
                    UIKit:showMessageDialog(_("主人"),_("金龙币不足"))
                        :CreateOKButton({
                            listener =  function ()
                                UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                                self:LeftButtonClicked()
                            end
                        })
                else
                    if app:GetGameDefautlt():IsOpenGemRemind() then
                        UIKit:showConfirmUseGemMessageDialog(_("提示"),string.format(_("是否消费%s金龙币"),
                            string.formatnumberthousands(
                                User:GetInstantUpgradeMilitaryTechGems(self.tech_name, self.tech)
                            )
                        ), function()
                            upgrade_listener()
                        end,true,true)
                    else
                        upgrade_listener()
                    end
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
                    NetManager:getUpgradeMilitaryTechPromise(self.tech_name)
                    self:LeftButtonClicked()
                    local tech_ui = UIKit:GetUIInstance("GameUIMilitaryTechBuilding")
                    if tech_ui then
                        tech_ui:LeftButtonClicked()
                    end
                end
                local results = User:CanUpgrade(self.tech_name, self.tech)
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
        text = User:GetInstantUpgradeMilitaryTechGems(self.tech_name, self.tech),
        size = 20,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,size.width/2 - 230,size.height-294):addTo(body)
    --升级所需时间
    display.newSprite("hourglass_30x38.png", size.width/2+100, size.height-290):addTo(body):setScale(0.6)
    self.upgrade_time = UIKit:ttfLabel({
        text = GameUtils:formatTimeStyle1(UtilsForTech:GetTechInfo(self.tech_name, self.tech.level + 1).buildTime),
        size = 18,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,size.width/2+125,size.height-280):addTo(body)

    -- 科技减少升级时间
    self.buff_reduce_time = UIKit:ttfLabel({
        text = "(-"..GameUtils:formatTimeStyle1(DataUtils:getTechnilogyUpgradeBuffTime(
            User:GetMilitaryTechUpgradeTime(self.tech_name, self.tech.level)
        ))..")",
        size = 18,
        color = 0x068329
    }):align(display.LEFT_CENTER,size.width/2+120,size.height-300):addTo(body)
end
function WidgetUpgradeMilitaryTech:UpgradeRequirement()
    local User = User
    local tech = self.tech
    local body = self.body
    local size = body:getContentSize()
    local level_up_config = UtilsForTech:GetTechInfo(self.tech_name, self.tech.level + 1)
    local has_materials = User.technologyMaterials
    local current_coin = User:GetResValueByType("coin")

    local requirements = {
        {
            resource_type = "building_queue",
            isVisible = User:GetMilitaryTechEventsNumber(self.tech.building)>0,
            isSatisfy = not User:HasMilitaryTechEventBy(self.tech.building),
            icon="hammer_33x40.png",

            description= string.format( _("升级队列已满:%d/1"), (1-User:GetMilitaryTechEventsNumber(self.tech.building)) ),
        },
        {
            resource_type = Localize.fight_reward.coin,
            isVisible = level_up_config.coin>0,
            isSatisfy = current_coin >= level_up_config.coin,
            icon=UILib.resource.coin,description=current_coin..'/'..level_up_config.coin
        },
        {
            resource_type = Localize.sell_type.trainingFigure,
            isVisible = level_up_config.trainingFigure>0,
            isSatisfy = has_materials.trainingFigure >= level_up_config.trainingFigure,
            icon=UILib.materials.trainingFigure,
            description=has_materials.trainingFigure..'/'..level_up_config.trainingFigure
        },
        {
            resource_type = Localize.sell_type.bowTarget,
            isVisible = level_up_config.bowTarget>0,
            isSatisfy = has_materials.bowTarget >= level_up_config.bowTarget,
            icon=UILib.materials.bowTarget,
            description=has_materials.bowTarget..'/'..level_up_config.bowTarget
        },
        {
            resource_type = Localize.sell_type.saddle,
            isVisible = level_up_config.saddle>0,
            isSatisfy = has_materials.saddle >= level_up_config.saddle,
            icon=UILib.materials.saddle,
            description=has_materials.saddle..'/'..level_up_config.saddle
        },
        {
            resource_type = Localize.sell_type.ironPart,
            isVisible = level_up_config.ironPart>0,
            isSatisfy = has_materials.ironPart >= level_up_config.ironPart,
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
function WidgetUpgradeMilitaryTech:PopNotSatisfyDialog(upgrade_listener,results)
    local message = ""
    for k,v in pairs(results) do
        message = message .. v.."\n"
    end
    local need_gems = User:GetNormalUpgradeMilitaryTechGems(self.tech_name, self.tech)
    local current_gem = User:GetGemValue()
    UIKit:showMessageDialog(_("主人"),message)
        :CreateOKButtonWithPrice({
            listener =  current_gem < need_gems and function ()
                UIKit:showMessageDialog(_("主人"),_("金龙币不足"))
                    :CreateOKButton({
                        listener =  function ()
                            UIKit:newGameUI("GameUIStore"):AddToCurrentScene(true)
                            self:LeftButtonClicked()
                        end,
                        btn_name = _("前往商店")
                    })
            end
            or upgrade_listener,
            price = need_gems
        })
        :CreateCancelButton()
end
function WidgetUpgradeMilitaryTech:OnUserDataChanged_militaryTechs(userData, deltaData)
    local ok, value = deltaData("militaryTechs")
    if ok then
        for tech_name,v in pairs(value) do
            if tech_name == self.tech_name then
                local tech = userData.militaryTechs[tech_name]
                if UtilsForTech:IsMaxLevel(tech_name, tech) then
                    self:LeftButtonClicked()
                    return
                end
                local buildTime = UtilsForTech:GetTechInfo(self.tech_name, tech.level + 1).buildTime
                self.upgrade_time:setString(GameUtils:formatTimeStyle1(buildTime))

                local gems = userData:GetInstantUpgradeMilitaryTechGems(tech_name, tech)
                self.upgrade_now_need_gems_label:setString(string.formatnumberthousands(gems))

                self.upgrade_tip:setString(UtilsForTech:GetTechLocalize(tech_name).." Lv" .. tech.level)

                local effect = UtilsForTech:GetEffect(tech_name, tech)
                local next_effect = UtilsForTech:GetNextLevelEffect(tech_name, tech)
                self.line1:SetText((effect * 100).."%", (next_effect * 100).."%")

                local tech_point = UtilsForTech:GetTechPoint(tech_name, tech)
                local next_tech_point = UtilsForTech:GetTechPoint(tech_name, tech)
                self.line2:SetText(tech_point, next_tech_point)

                self:UpgradeRequirement()
            end
        end
    end
end
return WidgetUpgradeMilitaryTech



















