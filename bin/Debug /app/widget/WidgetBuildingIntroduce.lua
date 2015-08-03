local WidgetPopDialog = import(".WidgetPopDialog")
local WidgetRequirementListview = import(".WidgetRequirementListview")
local MaterialManager = import("..entity.MaterialManager")
local Localize = import("..utils.Localize")
local SpriteConfig = import("..sprites.SpriteConfig")

local WidgetBuildingIntroduce = class("WidgetBuildingIntroduce", WidgetPopDialog)

function WidgetBuildingIntroduce:ctor(building)
    WidgetBuildingIntroduce.super.ctor(self,500,_("升级条件"),display.top - 280)
    self.building = building
    self.city = City
    local body = self.body
    local size = body:getContentSize()
    local width,height = size.width,size.height

    -- 建筑功能介绍
    local building_bg = display.newSprite("alliance_item_flag_box_126X126.png")
        :align(display.LEFT_TOP, 24, height - 30)
        :scale(136/126)
        :addTo(body)

    local build_png = SpriteConfig[building:GetType()]:GetConfigByLevel(1).png
    local building_image = display.newScale9Sprite(build_png, building_bg:getContentSize().width/2, building_bg:getContentSize().height/2):addTo(building_bg)
    building_image:setAnchorPoint(cc.p(0.5,0.5))
    building_image:setScale(90/math.max(building_image:getContentSize().width,building_image:getContentSize().height))

    local configs = SpriteConfig[building:GetType()]:GetAnimationConfigsByLevel(1)
    local p = building_image:getAnchorPointInPoints()
    for _,v in ipairs(configs) do
        if v.deco_type == "image" then
            display.newSprite(v.deco_name):addTo(building_image)
                :pos(p.x + v.offset.x, p.y + v.offset.y)
        elseif v.deco_type == "animation" then
            local offset = v.offset
            local armature = ccs.Armature:create(v.deco_name)
                :addTo(building_image):scale(v.scale or 1)
                :align(display.CENTER, offset.x or p.x, offset.y or p.y)
            armature:getAnimation():setSpeedScale(2)
            armature:getAnimation():playWithIndex(0)
        end
    end

    local title_bg = display.newScale9Sprite("title_blue_430x30.png", width/2 - 116, height - 30,cc.size(380,30),cc.rect(15,10,400,10))
        :align(display.LEFT_TOP)
        :addTo(body)
    local bd = Localize.building_name
    local building_name = UIKit:ttfLabel({
        text = bd[building:GetType()],
        size = 24,
        color = 0xffedae
    }):align(display.LEFT_CENTER,20, 15):addTo(title_bg)
    local bd = Localize.building_description
    local building_introduces = UIKit:ttfLabel({
        text = bd[building:GetType()],
        size = 20,
        dimensions = cc.size(380, 0),
        color = 0x615b44
    }):align(display.LEFT_TOP,width/2 - 116, height - 70):addTo(body)
    self:SetUpgradeRequirementListview()
end


function WidgetBuildingIntroduce:SetUpgradeRequirementListview()
    local city = self.city
    local wood = city.resource_manager:GetWoodResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local iron = city.resource_manager:GetIronResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local stone = city.resource_manager:GetStoneResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())
    local population = city.resource_manager:GetCitizenResource():GetResourceValueByCurrentTime(app.timer:GetServerTime())

    local materials = city:GetMaterialManager():GetMaterialsByType(MaterialManager.MATERIAL_TYPE.BUILD)

    local requirements = {
        {
            resource_type = "building_queue",
            isVisible = #city:GetUpgradingBuildings()>=city:BuildQueueCounts(),
            isSatisfy = #city:GetUpgradingBuildings()<city:BuildQueueCounts(),
            icon="hammer_33x40.png",
            description=_("建造队列已满")..(city:BuildQueueCounts()-#city:GetUpgradingBuildings()).."/"..1
        },
        
        {resource_type = _("木材"),isVisible = self.building:GetLevelUpWood()>0,      isSatisfy = wood>self.building:GetLevelUpWood(),
            icon="res_wood_82x73.png",description=self.building:GetLevelUpWood().."/"..wood},

        {resource_type = _("石料"),isVisible = self.building:GetLevelUpStone()>0,     isSatisfy = stone>self.building:GetLevelUpStone() ,
            icon="res_stone_88x82.png",description=self.building:GetLevelUpStone().."/"..stone},

        {resource_type = _("铁矿"),isVisible = self.building:GetLevelUpIron()>0,      isSatisfy = iron>self.building:GetLevelUpIron() ,
            icon="res_iron_91x63.png",description=self.building:GetLevelUpIron().."/"..iron},

        {
            resource_type = _("空闲城民"),
            isVisible = self.building:GetLevelUpCitizen()>0,
            isSatisfy = population>= self.building:GetLevelUpCitizen() ,
            icon="res_citizen_88x82.png",
            description=population.."/"..self.building:GetLevelUpCitizen()
        },
        {
            resource_type = _("工程图纸"),
            isVisible = self.building:GetLevelUpBlueprints()>0,
            isSatisfy = materials["blueprints"]>self.building:GetLevelUpBlueprints() ,
            icon="blueprints_128x128.png",
            description=self.building:GetLevelUpBlueprints().."/"..materials["blueprints"]
        },
        {
            resource_type = _("建造工具"),
            isVisible = self.building:GetLevelUpTools()>0,
            isSatisfy = materials["tools"]>self.building:GetLevelUpTools() ,
            icon="tools_128x128.png",
            description=self.building:GetLevelUpTools().."/"..materials["tools"]
        },
        {
            resource_type =_("砖石瓦片"),
            isVisible = self.building:GetLevelUpTiles()>0,
            isSatisfy = materials["tiles"]>self.building:GetLevelUpTiles() ,
            icon="tiles_128x128.png",
            description=self.building:GetLevelUpTiles().."/"..materials["tiles"]
        },
        {
            resource_type = _("滑轮组"),
            isVisible = self.building:GetLevelUpPulley()>0,
            isSatisfy = materials["pulley"]>self.building:GetLevelUpPulley() ,
            icon="pulley_128x128.png",
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


