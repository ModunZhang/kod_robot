--
-- Author: Kenny Dai
-- Date: 2015-01-17 10:33:17
--
local window = import("..utils.window")
local WidgetProgress = import(".WidgetProgress")
local WidgetUIBackGround = import(".WidgetUIBackGround")
local WidgetPushButton = import(".WidgetPushButton")
local SoldierManager = import("..entity.SoldierManager")
local Localize = import("..utils.Localize")

local function create_line_item(icon,text_1,text_2,text_3)
    local line = display.newScale9Sprite("dividing_line.png",0,0,cc.size(384,2),cc.rect(10,2,382,2))
    local icon = display.newSprite(icon):addTo(line,2):align(display.LEFT_BOTTOM, 0, 2)
    icon:scale(32/icon:getContentSize().width)
    local text1 = UIKit:ttfLabel({
        text = text_1,
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_BOTTOM, 40 , 2)
        :addTo(line)
    local green_icon = display.newSprite("teach_upgrade_icon_15x17.png"):align(display.BOTTOM_CENTER, 320 , 6):addTo(line)
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

local WidgetMilitaryTechnology = class("WidgetMilitaryTechnology", function ()
    local list,list_node = UIKit:commonListView({
        viewRect = cc.rect(0, 0,568, 560),
        direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
    })
    list_node.listview = list
    list_node:setNodeEventEnabled(true)
    return list_node
end)

function WidgetMilitaryTechnology:ctor(building)
    self.building = building

    local techs = City:GetSoldierManager():FindMilitaryTechsByBuildingType(self.building:GetType())
    self.items_list = {}
    for k,v in pairs(techs) do
        self.items_list[v:Name()] =  self:CreateItem(v)
    end
    self:VisibleUpgradeButton()
    self.listview:reload()
end

function WidgetMilitaryTechnology:CreateItem(tech)
    local list = self.listview
    local item = list:newItem()
    local item_width,item_height = 568,150
    item:setItemSize(item_width,item_height)
    list:addItem(item)

    local content = WidgetUIBackGround.new({width = item_width,height = item_height},WidgetUIBackGround.STYLE_TYPE.STYLE_2)
    item:addContent(content)

    local title_bg = display.newScale9Sprite("title_blue_430x30.png",item_width/2,item_height-25,cc.size(550,30),cc.rect(15,10,400,10))
        :addTo(content)
    local temp = UIKit:ttfLabel({
        text = tech:GetTechLocalize() ,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, 20 , title_bg:getContentSize().height/2)
        :addTo(title_bg)
    local tech_level = UIKit:ttfLabel({
        text = string.format("Lv%d",tech:Level()) ,
        size = 22,
        color = 0xffedae,
    }):align(display.LEFT_CENTER, temp:getPositionX()+temp:getContentSize().width+20 , title_bg:getContentSize().height/2)
        :addTo(title_bg)

    local upgrade_btn = WidgetPushButton.new({normal = "blue_btn_up_148x58.png",pressed = "blue_btn_down_148x58.png"})
        :setButtonLabel(UIKit:ttfLabel({
            text = _("研发"),
            size = 22,
            color = 0xffedae,
            shadow = true
        })):onButtonClicked(function (event)
        UIKit:newWidgetUI("WidgetUpgradeMilitaryTech", tech):AddToCurrentScene()
        end)
        :align(display.CENTER, item_width-90, 44):addTo(content)

    local soldiers = string.split(tech:Name(), "_")
    local soldier_category = Localize.soldier_category
    local line1 = create_line_item("battle_33x33.png",tech:GetTechLocalize(),tech:IsMaxLevel() and "" or (tech:GetAtkEff()*100).."%",(tech:GetNextLevlAtkEff()*100).."%"):addTo(content):align(display.LEFT_CENTER, 10, 60)
    local line2 = create_line_item("bottom_icon_package_77x67.png",tech:GetTechCategory(),tech:IsMaxLevel() and "" or tech:GetTechPoint(),tech:GetNextLevlTechPoint()):addTo(content):align(display.LEFT_CENTER, 10, 20)

    function item:LevelUpRefresh(tech)
        tech_level:setString(string.format("Lv%d",tech:Level()))
        if tech:IsMaxLevel() then
            upgrade_btn:hide()
            line1:SetText(nil,(tech:GetAtkEff()*100).."%")
            line2:SetText(nil,tech:GetNextLevlTechPoint())
        else
            line1:SetText((tech:GetAtkEff()*100).."%",(tech:GetNextLevlAtkEff()*100).."%")
            line2:SetText(tech:GetTechPoint(),tech:GetNextLevlTechPoint())
        end
    end
    function item:GetTech()
        return tech
    end
    function item:SetUpgradeBtnVisible(visible)
        upgrade_btn:setVisible(visible and not tech:IsMaxLevel())
    end
    return item
end
function WidgetMilitaryTechnology:onEnter()
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
end
function WidgetMilitaryTechnology:onExit()
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_EVENTS_CHANGED)
end
function WidgetMilitaryTechnology:OnMilitaryTechsDataChanged(soldier_manager,changed_map)
    for k,v in pairs(changed_map) do
        print("OnMilitaryTechsDataChanged>>>",k,v:Level())
        if self.items_list[k] then
            self.items_list[k]:LevelUpRefresh(v)
        end
    end
end
function WidgetMilitaryTechnology:OnMilitaryTechEventsChanged(soldier_manager,changed_map)
    self:VisibleUpgradeButton()
end
function WidgetMilitaryTechnology:VisibleUpgradeButton()
    for i,v in pairs(self.items_list) do
        local visible = true
        City:GetSoldierManager():IteratorMilitaryTechEvents(function (event)
            if v:GetTech():Name() == event:Name() then
                visible = false
                return
            end
        end)
        v:SetUpgradeBtnVisible(visible)
    end
end
return WidgetMilitaryTechnology












