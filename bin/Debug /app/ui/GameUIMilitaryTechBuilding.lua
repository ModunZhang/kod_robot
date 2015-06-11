--
-- Author: Kenny Dai
-- Date: 2015-01-19 16:38:27
--

local Localize = import("..utils.Localize")
local window = import("..utils.window")
local SoldierManager = import("..entity.SoldierManager")
local WidgetMilitaryTechnologyStatus = import("..widget.WidgetMilitaryTechnologyStatus")
local WidgetMilitaryTechnology = import("..widget.WidgetMilitaryTechnology")
local WidgetPromoteSoliderList = import("..widget.WidgetPromoteSoliderList")

-- 建筑名map对应科技
local building_map_tech = {
    trainingGround = _("步兵科技"),
    stable         = _("骑兵科技"),
    hunterHall     = _("弓手科技"),
    workshop       = _("攻城科技"),
}

local GameUIMilitaryTechBuilding = UIKit:createUIClass('GameUIMilitaryTechBuilding',"GameUIUpgradeBuilding")
function GameUIMilitaryTechBuilding:ctor(city,building,default_tab)
    local bn = Localize.building_name
    GameUIMilitaryTechBuilding.super.ctor(self,city,bn[building:GetType()],building,default_tab)
end

function GameUIMilitaryTechBuilding:OnMoveInStage()
    GameUIMilitaryTechBuilding.super.OnMoveInStage(self)
    self:CreateTabButtons({
        {
            label = _("科技"),
            tag = "tech",
        },
        {
            label = _("晋升"),
            tag = "promote",
        },
    },
    function(tag)
        if tag == 'tech' then
            self.tech_layer:setVisible(true)
            self.promote_layer:setVisible(false)
            if not self.teac_list then
                self:InitTech()
            end
            if not self.status then
                -- 军事科技升级状态
                self.status = WidgetMilitaryTechnologyStatus.new(self.building):addTo(self:GetView(),2):pos(window.cx, window.top_bottom)
            end
            self.status:setVisible(true)
        elseif tag == 'promote' then
            self.tech_layer:setVisible(false)
            self.promote_layer:setVisible(true)
            if not self.promote_list then
                self:InitPromote()
            end
            if not self.status then
                -- 军事科技升级状态
                self.status = WidgetMilitaryTechnologyStatus.new(self.building):addTo(self:GetView(),2):pos(window.cx, window.top_bottom)
            end
            self.status:setVisible(true)
        else
            self.tech_layer:setVisible(false)
            self.promote_layer:setVisible(false)
            if self.status then
                self.status:setVisible(false)
            end
        end
    end):pos(window.cx, window.bottom + 34)
    City:GetSoldierManager():AddListenOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
end
function GameUIMilitaryTechBuilding:onExit()
    City:GetSoldierManager():RemoveListenerOnType(self,SoldierManager.LISTEN_TYPE.MILITARY_TECHS_DATA_CHANGED)
    GameUIMilitaryTechBuilding.super.onExit(self)
end
function GameUIMilitaryTechBuilding:CreateBetweenBgAndTitle()
    GameUIMilitaryTechBuilding.super.CreateBetweenBgAndTitle(self)


    -- 科技 layer
    self.tech_layer = display.newLayer():addTo(self:GetView())

    -- 晋升 layer
    self.promote_layer = display.newLayer():addTo(self:GetView())
end

function GameUIMilitaryTechBuilding:InitTech()
    self.teac_list = WidgetMilitaryTechnology.new(self.building):addTo(self.tech_layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)

    -- 科技点数
    local tech_point_bg = display.newScale9Sprite("back_ground_166x84.png", 0,0,cc.size(548,52),cc.rect(15,10,136,64))
    :addTo(self.tech_layer):align(display.CENTER, window.cx, window.top-244)
    display.newSprite("bottom_icon_package_77x67.png"):addTo(tech_point_bg):align(display.CENTER,30,tech_point_bg:getContentSize().height/2):scale(0.5)
    UIKit:ttfLabel({
        text = building_map_tech[self.building:GetType()],
        size = 20,
        color = 0x615b44,
    }):align(display.LEFT_CENTER, 50 , tech_point_bg:getContentSize().height/2)
        :addTo(tech_point_bg)

    -- 科技点数
    self.tech_point_label = UIKit:ttfLabel({
        text = City:GetSoldierManager():GetTechPointsByType(self.building:GetType()),
        size = 22,
        color = 0x403c2f,
    }):align(display.RIGHT_CENTER, tech_point_bg:getContentSize().width-30 , tech_point_bg:getContentSize().height/2)
        :addTo(tech_point_bg)
end
function GameUIMilitaryTechBuilding:InitPromote()
    self.promote_list = WidgetPromoteSoliderList.new(self.building):addTo(self.promote_layer):align(display.BOTTOM_CENTER, window.cx, window.bottom_top+20)
end
function GameUIMilitaryTechBuilding:OnMilitaryTechsDataChanged(soldier_manager,changed_map)
    if self.tech_point_label then
        self.tech_point_label:setString(soldier_manager:GetTechPointsByType(self.building:GetType()))
    end
end
return GameUIMilitaryTechBuilding



