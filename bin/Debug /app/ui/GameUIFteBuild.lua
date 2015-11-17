local GameUIFteBuild = UIKit:createUIClass('GameUIFteBuild', "GameUIBuild")

function GameUIFteBuild:ctor(...)
	GameUIFteBuild.super.ctor(self, ...)
	self.__type  = UIKit.UITYPE.BACKGROUND
end

--- fte
local check = import("..fte.check")
local mockData = import("..fte.mockData")
local DiffFunction = import("..utils.DiffFunction")
local WidgetFteArrow = import("..widget.WidgetFteArrow")
function GameUIFteBuild:Find(building_type)
    local item
    table.foreach(self.base_resource_building_items, function(_, v)
        if v.building.building_type == building_type then
            item = v:GetBuildButton()
        else
            v.SetBuildEnable = function()end
            v:GetBuildButton():setButtonEnabled(false)
        end
    end)
    return item
end
local house_map = setmetatable({
    dwelling = _("建造住宅, 提升城民上限"),
}, {__index = function() return _("点击建造") end})
function GameUIFteBuild:PromiseOfFte(house_type)
    self.base_list_view:getScrollNode():setTouchEnabled(false)
    self:GetFteLayer():SetTouchObject(self:Find(house_type))

    local city = self.build_city
    
    local building_location_id, house_location_id = self:GetHouseLocations()
    self:Find(house_type):removeEventListenersByEvent("CLICKED_EVENT")
    self:Find(house_type):onButtonClicked(function()
        self:Find(house_type):setButtonEnabled(false)

        mockData.BuildHouseAt(building_location_id, house_location_id, house_type)

        self:LeftButtonClicked()
    end)

    local r = self:Find(house_type):getCascadeBoundingBox()
    self:Find(house_type):setTouchSwallowEnabled(true)
    self:GetFteLayer().arrow = WidgetFteArrow.new(house_map[house_type]):addTo(self:GetFteLayer())

    if house_type == "dwelling" then
        self:GetFteLayer().arrow:TurnRight():align(display.RIGHT_CENTER, r.x - 20, r.y + r.height/2 )
    else
        self:GetFteLayer().arrow:TurnDown():align(display.BOTTOM_CENTER, r.x + r.width/2, r.y + r.height + 10)
    end

    return city:PromiseOfUpgradingByLevel(house_type, 0)
end
function GameUIFteBuild:GetHouseLocations()
    local x,y = self.select_ruins:GetLogicPosition()
    local tile = self.build_city:GetTileByBuildingPosition(x, y)
    return tile.location_id, tile:GetBuildingLocation(self.select_ruins)
end



return GameUIFteBuild