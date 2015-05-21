local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetRequirementListview = import(".WidgetRequirementListview")
local MaterialManager = import("..entity.MaterialManager")
local Localize = import("..utils.Localize")

local WidgetBuildingIntroduce = class("WidgetBuildingIntroduce", WidgetPopDialog)

function WidgetBuildingIntroduce:ctor(building)
    WidgetBuildingIntroduce.super.ctor(self,420,_("升级条件"),display.top - 300)
    self.building = building
    self.city = City
    local body = self.body
    local size = body:getContentSize()
    local width,height = size.width,size.height
    UIKit:ttfLabel({
        text = Localize.building_name[building:GetType()].."(LV"..building:GetLevel()..")",
        size = 24,
        color = 0x403c2f
    }):align(display.LEFT_CENTER,30,height-50)
        :addTo(body)
    self:SetUpgradeRequirementListview()
end


function WidgetBuildingIntroduce:SetUpgradeRequirementListview()
    local wood = City.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = City.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = City.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local population = City.resource_manager:GetPopulationResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())

    local materials = self.city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)
    local requirements = {
        {resource_type = _("建造队列"),isVisible = true, isSatisfy = #City:GetUpgradingBuildings()<1,
            icon="hammer_33x40.png",description=(City:BuildQueueCounts()-#City:GetUpgradingBuildings()).."/1"},
        {resource_type = _("木材"),isVisible = self.building:GetLevelUpWood()>0,      isSatisfy = wood>self.building:GetLevelUpWood(),
            icon="res_wood_82x73.png",description=self.building:GetLevelUpWood().."/"..wood},

        {resource_type = _("石料"),isVisible = self.building:GetLevelUpStone()>0,     isSatisfy = stone>self.building:GetLevelUpStone() ,
            icon="res_stone_88x82.png",description=self.building:GetLevelUpStone().."/"..stone},

        {resource_type = _("铁矿"),isVisible = self.building:GetLevelUpIron()>0,      isSatisfy = iron>self.building:GetLevelUpIron() ,
            icon="res_iron_91x63.png",description=self.building:GetLevelUpIron().."/"..iron},


        {
            resource_type = _("建筑蓝图"),
            isVisible = self.building:GetLevelUpBlueprints()>0,
            isSatisfy = materials["blueprints"]>self.building:GetLevelUpBlueprints() ,
            icon="blueprints_112x112.png",
            description=self.building:GetLevelUpBlueprints().."/"..materials["blueprints"]
        },
        {
            resource_type = _("建造工具"),
            isVisible = self.building:GetLevelUpTools()>0,
            isSatisfy = materials["tools"]>self.building:GetLevelUpTools() ,
            icon="tools_112x112.png",
            description=self.building:GetLevelUpTools().."/"..materials["tools"]
        },
        {
            resource_type =_("砖石瓦片"),
            isVisible = self.building:GetLevelUpTiles()>0,
            isSatisfy = materials["tiles"]>self.building:GetLevelUpTiles() ,
            icon="tiles_112x112.png",
            description=self.building:GetLevelUpTiles().."/"..materials["tiles"]
        },
        {
            resource_type = _("滑轮组"),
            isVisible = self.building:GetLevelUpPulley()>0,
            isSatisfy = materials["pulley"]>self.building:GetLevelUpPulley() ,
            icon="pulley_112x112.png",
            description=self.building:GetLevelUpPulley().."/"..materials["pulley"]
        },
    }

    if not self.requirement_listview then
        self.requirement_listview = WidgetRequirementListview.new({
            title = _("建筑描述"),
            height = 250,
            contents = requirements,
        }):addTo(self.body):pos(30,20)
    end
    self.requirement_listview:RefreshListView(requirements)
end
return WidgetBuildingIntroduce


